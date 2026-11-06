# frozen_string_literal: true

require "json"

module Veille
  # Official Veille API client. Create one instance and reuse it.
  class Client
    include Operations

    DEFAULT_BASE_URL = "https://api.veille.io"
    DEFAULT_TIMEOUT = 120
    # Tasks run at the same time by #batch.
    DEFAULT_CONCURRENCY = 10
    # Retries after a network error or a 408, 429, 500, 502, 503 or 504 response.
    MAX_RETRIES = 3
    # Each retry waits this many times longer than the previous one (a Retry-After header wins).
    RETRY_BACKOFF_FACTOR = 1.5
    # Seconds before the first retry.
    DEFAULT_RETRY_DELAY = 1.0
    MAX_RETRY_DELAY = 30.0
    RETRYABLE_STATUSES = [408, 500, 502, 503, 504].freeze
    API_KEY_ENVIRONMENT_VARIABLE = "VEILLE_API_KEY"
    JOB_TERMINAL_STATUSES = %w[CompletedJob Error NotFound BadRequest].freeze
    ERROR_MESSAGE_KEYS = %w[error message error_message detail].freeze

    # @param api_key [String, nil] defaults to ENV["VEILLE_API_KEY"]
    # @param base_url [String] API origin
    # @param timeout [Numeric, nil] seconds per request; nil disables it
    # @param headers [Hash] extra headers for every request
    # @param max_retries [Integer] retries after a network error or a 408/429/5xx response; 0 disables them
    # @param retry_delay [Numeric] seconds before the first retry, growing 1.5x per retry
    # @param transport [#call] custom transport, see {NetHTTPTransport}
    def initialize(api_key: nil, base_url: DEFAULT_BASE_URL, timeout: DEFAULT_TIMEOUT, headers: {},
                   max_retries: MAX_RETRIES, retry_delay: DEFAULT_RETRY_DELAY, transport: nil)
      api_key = ENV.fetch(API_KEY_ENVIRONMENT_VARIABLE, nil) if api_key.nil?
      if !api_key.is_a?(String) || api_key.strip.empty?
        raise ConfigurationError,
              "A non-blank Veille API key is required. Pass api_key: or set #{API_KEY_ENVIRONMENT_VARIABLE}."
      end
      raise ConfigurationError, "The Veille API key cannot be used in an HTTP header." if api_key.match?(/[\r\n]/)

      uri = URI.parse(base_url.to_s)
      unless %w[http https].include?(uri.scheme) && uri.host
        raise ConfigurationError, "base_url must be an absolute http or https URL."
      end
      raise ConfigurationError, "timeout must be a positive number or nil." if timeout && !(timeout.is_a?(Numeric) && timeout.positive?)
      raise ConfigurationError, "transport must respond to #call." if transport && !transport.respond_to?(:call)

      @api_key = api_key
      @base_url = base_url.to_s.sub(%r{/+\z}, "")
      @timeout = timeout
      @headers = headers.to_h { |name, value| [name.to_s, value.to_s] }.freeze
      raise ConfigurationError, "max_retries must be a non-negative Integer." unless max_retries.is_a?(Integer) && max_retries >= 0
      raise ConfigurationError, "retry_delay must be a non-negative number." unless retry_delay.is_a?(Numeric) && retry_delay >= 0

      @max_retries = max_retries
      @retry_delay = retry_delay
      @transport = transport || NetHTTPTransport.new
    end

    def inspect
      "#<#{self.class.name} base_url=#{@base_url.inspect}>"
    end

    # Sends any request, including endpoints released after this SDK version.
    # GET parameters travel in the query string; POST parameters travel in a JSON body.
    # @return [JsonResponse, BinaryResponse]
    def request(method, path, params = nil, timeout: nil, headers: nil, max_retries: nil)
      send_request(method.to_s.upcase, path, params, { timeout: timeout, headers: headers, max_retries: max_retries }, :any)
    end

    # Runs the block for every item on +concurrency+ threads (default 10) and returns one {BatchResult} per item,
    # in input order. A failing item never stops the others; the client is thread-safe.
    #
    #   results = client.batch(ids, concurrency: 5) { |id| client.some_endpoint(query: id) }
    # @return [Array<BatchResult>]
    def batch(items, concurrency: DEFAULT_CONCURRENCY)
      raise ConfigurationError, "concurrency must be a positive Integer." unless concurrency.is_a?(Integer) && concurrency.positive?
      raise ArgumentError, "batch needs a block" unless block_given?

      list = items.to_a
      results = Array.new(list.size)
      queue = Queue.new
      list.each_with_index { |item, index| queue << [item, index] }
      queue.close
      workers = Array.new([concurrency, list.size].min) do
        Thread.new do
          while (job = queue.pop)
            item, index = job
            results[index] = begin
              BatchResult.new(index: index, value: yield(item), error: nil)
            rescue StandardError => e
              BatchResult.new(index: index, value: nil, error: e)
            end
          end
        end
      end
      workers.each(&:join)
      results
    end

    # Polls GET /v1/jobs/{id} until the job reaches a terminal status. The delay starts at +interval+ seconds
    # and grows 1.5x per poll up to 60 s; +timeout+ defaults to 12 hours.
    # @yieldparam job [Hash] the latest job document after every poll
    # @return [JsonResponse]
    def wait_for_job(job_id, interval: 3, timeout: 43_200)
      raise SerializationError.new("A non-blank job id is required.", "id") if job_id.to_s.strip.empty?

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      loop do
        last = request("GET", "/v1/jobs/{id}", { "id" => job_id })
        yield last.data if block_given?
        return last if last.data.is_a?(Hash) && JOB_TERMINAL_STATUSES.include?(last.data["status"])

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        raise JobTimeoutError.new(job_id, last) if elapsed + interval > timeout

        sleep(interval)
        interval = (interval * 1.5).clamp(interval, [interval, 60].max)
      end
    end

    private

    def call_operation(name, params, options)
      endpoint = ENDPOINTS.fetch(name)
      options = (options || {}).transform_keys(&:to_sym)
      method = (options[:method] || endpoint[:methods].first).to_s.upcase
      unless endpoint[:methods].include?(method)
        raise ConfigurationError, "#{endpoint[:path]} supports #{endpoint[:methods].join(', ')}, not #{method}."
      end

      params = params.transform_keys(&:to_s)
      unknown = params.keys - endpoint[:params]
      unless unknown.empty?
        raise SerializationError.new(
          "Unknown parameter(s) for #{name}: #{unknown.join(', ')}. Use #request for undocumented parameters.",
          unknown.first
        )
      end
      endpoint[:required].each do |required|
        raise SerializationError.new("The \"#{required}\" parameter is required.", required) if params[required].nil?
      end
      send_request(method, endpoint[:path], params, options, endpoint[:response])
    end

    def send_request(method, path, params, options, expected)
      raise ConfigurationError, "Unsupported HTTP method: #{method.inspect}." unless %w[GET POST].include?(method)
      raise ConfigurationError, 'The request path must start with "/".' unless path.is_a?(String) && path.start_with?("/")

      path, pairs, body = Serialization.serialize(method, path, params)
      url = @base_url + path
      url += "?#{Serialization.encode_query(pairs)}" unless pairs.empty?
      headers = {
        "Accept" => "application/json, */*;q=0.8",
        "User-Agent" => "veille-ruby/#{VERSION}"
      }.merge(@headers).merge((options[:headers] || {}).to_h { |k, v| [k.to_s, v.to_s] })
      headers["x-api-key"] = @api_key
      payload = nil
      if body
        headers["Content-Type"] = "application/json"
        payload = JSON.generate(body)
      end

      max_retries = options[:max_retries] || @max_retries
      attempt = 0
      loop do
        begin
          status, response_headers, response_body = @transport.call(
            method: method, url: url, headers: headers, body: payload, timeout: options[:timeout] || @timeout
          )
        rescue Timeout::Error => e
          raise TransportError, "Veille request timed out: #{e.message}"
        rescue StandardError => e
          raise TransportError, "Veille request failed before an HTTP response was received: #{e.message}" if attempt >= max_retries

          sleep(retry_delay(attempt, nil))
          attempt += 1
          next
        end
        raw = build_raw_response(status, response_headers, response_body)
        return decode(raw, expected) if (200..299).cover?(raw.status)
        raise api_error(raw) unless retryable?(raw) && attempt < max_retries

        sleep(retry_delay(attempt, raw.headers["retry-after"]&.first))
        attempt += 1
      end
    end

    # Server errors and plan rate limits (401/429 "Rate limit exceeded") are retried; per-key quotas are not.
    def retryable?(raw)
      return true if RETRYABLE_STATUSES.include?(raw.status)
      return false unless [401, 429].include?(raw.status)

      message = api_error(raw).error_message.to_s.downcase
      return false if message.include?("quota")

      message.include?("rate limit") || (raw.status == 429 && message.empty?)
    end

    def retry_delay(attempt, retry_after)
      seconds = Float(retry_after, exception: false) if retry_after
      return [seconds, 60].min if seconds && seconds >= 0

      [@retry_delay * (RETRY_BACKOFF_FACTOR**attempt), MAX_RETRY_DELAY].min
    end

    def build_raw_response(status, headers, body)
      normalized = {}
      (headers || {}).each { |name, values| normalized[name.to_s.downcase] = Array(values).map(&:to_s).freeze }
      RawResponse.new(
        status: status.to_i,
        headers: normalized.freeze,
        content_type: normalized["content-type"]&.first,
        body: body.to_s.b
      )
    end

    def api_error(raw)
      parsed = parse_json(raw.body)
      message = nil
      if parsed.is_a?(Hash)
        ERROR_MESSAGE_KEYS.each do |key|
          value = parsed[key]
          if value.is_a?(String) && !value.empty?
            message = value
            break
          end
        end
      end
      APIError.new(raw_response: raw, response_body: parsed == NOT_JSON ? nil : parsed, error_message: message)
    end

    def decode(raw, expected)
      unless json_media_type?(raw.content_type)
        if expected == :json
          raise ResponseDecodingError.new("Veille returned a successful non-JSON response for a JSON operation.", raw)
        end

        return BinaryResponse.new(bytes: raw.body, content_type: raw.content_type, raw_response: raw)
      end
      data = parse_json(raw.body)
      if data == NOT_JSON
        raise ResponseDecodingError.new("Veille returned a successful JSON response that could not be decoded.", raw)
      end

      JsonResponse.new(data: data, raw_response: raw)
    end

    NOT_JSON = Object.new.freeze
    private_constant :NOT_JSON

    def parse_json(body)
      JSON.parse(body.dup.force_encoding(Encoding::UTF_8))
    rescue JSON::ParserError, EncodingError
      NOT_JSON
    end

    def json_media_type?(content_type)
      return false if content_type.nil?

      media_type = content_type.split(";", 2).first.strip.downcase
      media_type == "application/json" || media_type.end_with?("+json")
    end
  end
end
