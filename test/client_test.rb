# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    @transport = FakeTransport.new
    @client = Veille::Client.new(api_key: "test-key", transport: @transport)
  end

  def test_requires_api_key
    with_env("VEILLE_API_KEY", nil) do
      assert_raises(Veille::ConfigurationError) { Veille::Client.new }
    end
    assert_raises(Veille::ConfigurationError) { Veille::Client.new(api_key: "   ") }
    assert_raises(Veille::ConfigurationError) { Veille::Client.new(api_key: "k", base_url: "ftp://x") }
  end

  def test_reads_api_key_from_environment
    with_env("VEILLE_API_KEY", "env-key") do
      client = Veille::Client.new(transport: @transport)
      client.request("GET", "/v1/usage")
    end
    assert_equal "env-key", @transport.calls.first[:headers]["x-api-key"]
  end

  def test_featured_operation
    @transport.respond { json_response({ "hello" => "world" }) }
    response = @client.intelligence_email(query: "jane.doe@example.com")
    assert_instance_of Veille::JsonResponse, response
    assert_equal({ "hello" => "world" }, response.data)
    call = @transport.calls.first
    assert_equal "GET", call[:method]
    assert_equal "https://api.veille.io/v1/intelligence/email", call[:url].split("?").first
    assert_equal "test-key", call[:headers]["x-api-key"]
    assert_match(/\Aveille-ruby\//, call[:headers]["User-Agent"])
  end

  def test_query_serialization
    client = Veille::Client.new(api_key: "k", base_url: "https://example.test/", transport: @transport)
    client.request("GET", "/v1/anything",
                   { text: "a b&c", flag: false, count: 0, ratio: 1.5, whole: 2.0, list: %w[x y], nothing: nil })
    assert_equal "https://example.test/v1/anything?text=a%20b%26c&flag=false&count=0&ratio=1.5&whole=2&list=x&list=y",
                 @transport.calls.first[:url]
  end

  def test_post_sends_json_body
    @client.request("POST", "/v1/anything", { query: "x", page: 2, gone: nil })
    call = @transport.calls.first
    assert_equal "POST", call[:method]
    assert_equal "application/json", call[:headers]["Content-Type"]
    assert_equal({ "query" => "x", "page" => 2 }, JSON.parse(call[:body]))
    refute_includes call[:url], "?"
  end

  def test_post_keeps_global_parameters_in_query
    @client.request("POST", "/v1/anything", { query: "x", is_async: true, fields: "a" })
    call = @transport.calls.first
    assert_equal({ "query" => "x" }, JSON.parse(call[:body]))
    assert_equal "https://api.veille.io/v1/anything?fields=a&is_async=true", call[:url]
  end

  def test_path_parameters
    @client.request("GET", "/v1/items/{id}", { id: "a/b c", other: 1 })
    assert_equal "https://api.veille.io/v1/items/a%2Fb%20c?other=1", @transport.calls.first[:url]
    assert_raises(Veille::SerializationError) { @client.request("GET", "/v1/items/{id}", {}) }
  end

  def test_required_and_unknown_parameters
    assert_raises(Veille::SerializationError) { @client.intelligence_email }
    assert_raises(Veille::SerializationError) { @client.intelligence_email(query: "jane.doe@example.com", not_a_parameter: 1) }
    assert_empty @transport.calls
  end

  def test_unsupported_method
    assert_raises(Veille::ConfigurationError) do
      @client.intelligence_domain(query: "test", request_options: { method: "POST" })
    end
  end

  def test_every_endpoint
    Veille::ENDPOINTS.each do |name, endpoint|
      method = @client.respond_to?(name) ? name : "#{name}_endpoint"
      @client.public_send(method, **REQUIRED.fetch(name, {}))
      call = @transport.calls.last
      assert_equal "https://api.veille.io#{endpoint[:path].sub("{id}", "test")}", call[:url].split("?").first, name
      assert_equal endpoint[:methods].first, call[:method], name
    end
    assert_equal Veille::ENDPOINTS.size, @transport.calls.size
  end

  def test_binary_response
    @transport.respond { [200, { "content-type" => ["image/png"] }, "\x89PNG".b] }
    response = @client.request("GET", "/v1/anything")
    assert_instance_of Veille::BinaryResponse, response
    assert_equal "\x89PNG".b, response.bytes
    assert_equal "image/png", response.content_type
  end

  def test_non_json_success_for_json_operation
    @transport.respond { [200, { "content-type" => ["text/html"] }, "<html>"] }
    assert_raises(Veille::ResponseDecodingError) { @client.intelligence_email(query: "jane.doe@example.com") }
  end

  def test_api_error
    @transport.respond { json_response({ "error" => "Invalid API Key" }, 401) }
    error = assert_raises(Veille::APIError) { @client.request("GET", "/v1/usage") }
    assert_equal 401, error.status
    assert_equal "Invalid API Key", error.message
    assert_equal({ "error" => "Invalid API Key" }, error.response_body)
  end

  def test_non_json_error_body
    @transport.respond { [502, {}, "Bad gateway"] }
    error = assert_raises(Veille::APIError) { @client.request("GET", "/v1/usage", max_retries: 0) }
    assert_equal 502, error.status
    assert_equal "Bad gateway", error.raw_response.body
  end

  def test_transport_error
    @transport.respond { raise IOError, "network down" }
    assert_raises(Veille::TransportError) { @client.request("GET", "/v1/usage", max_retries: 0) }
  end

  def test_retries_then_succeeds
    client = Veille::Client.new(api_key: "k", transport: @transport, retry_delay: 0.001)
    calls = 0
    @transport.respond do
      calls += 1
      raise IOError, "reset" if calls == 1
      next [429, { "retry-after" => ["0"] }, "{}"] if calls == 2
      next json_response({}, 503) if calls == 3

      json_response({ "ok" => true })
    end
    assert client.request("GET", "/v1/usage").json?
    assert_equal 4, @transport.calls.size
  end

  def test_retry_limits_and_client_errors
    client = Veille::Client.new(api_key: "k", transport: @transport, retry_delay: 0.001, max_retries: 2)
    @transport.respond { json_response({ "error" => "busy" }, 503) }
    assert_raises(Veille::APIError) { client.request("GET", "/v1/usage") }
    assert_equal 3, @transport.calls.size
    @transport.respond { json_response({ "error" => "Payment required" }, 402) }
    assert_raises(Veille::APIError) { client.request("GET", "/v1/usage") }
    assert_equal 4, @transport.calls.size
  end

  def test_401_rate_limits_are_retried_but_not_quotas
    client = Veille::Client.new(api_key: "k", transport: @transport, retry_delay: 0.001)
    {
      "Rate limit exceeded: You've exceeded the rate limit on your subscription" => 2,
      "Rate limit exceeded for the API key: quota daily" => 1,
      "Invalid API Key" => 1
    }.each do |message, expected|
      calls = 0
      @transport.respond do
        calls += 1
        calls == 1 ? json_response({ "error" => message }, 401) : json_response({})
      end
      begin
        client.request("GET", "/v1/usage")
      rescue Veille::APIError
        nil
      end
      assert_equal expected, calls, message
    end
  end

  def test_global_parameters
    @client.intelligence_email(query: "jane.doe@example.com", fields: "a,b.c", is_async: true, soft_fail: false)
    query = URI.decode_www_form(URI(@transport.calls.first[:url]).query).to_h
    assert_equal "a,b.c", query["fields"]
    assert_equal "true", query["is_async"]
    assert_equal "false", query["soft_fail"]
  end

  def test_batch
    running = 0
    peak = 0
    lock = Mutex.new
    results = @client.batch(1..6, concurrency: 2) do |n|
      lock.synchronize { running += 1; peak = [peak, running].max }
      sleep 0.005
      lock.synchronize { running -= 1 }
      raise "boom" if n == 4

      n * 10
    end
    assert_equal 2, peak
    assert_equal [10, 20, 30, nil, 50, 60], results.map(&:value)
    refute results[3].ok?
    assert_equal (0..5).to_a, results.map(&:index)
  end

  def test_wait_for_job
    statuses = %w[Queued Running CompletedJob]
    @transport.respond { json_response({ "status" => statuses.shift, "progress" => 50 }) }
    seen = []
    job = @client.wait_for_job("abc", interval: 0.001) { |j| seen << j }
    assert_equal "CompletedJob", job.data["status"]
    assert_equal 3, @transport.calls.size
    assert_equal "https://api.veille.io/v1/jobs/abc", @transport.calls.first[:url]
    assert_equal 3, seen.size
  end

  def test_wait_for_job_times_out
    @transport.respond { json_response({ "status" => "Running" }) }
    assert_raises(Veille::JobTimeoutError) { @client.wait_for_job("abc", interval: 0.01, timeout: 0.001) }
  end

  REQUIRED = {
    "intelligence_domain" => { query: "test" },
    "intelligence_email" => { query: "john@example.com" },
    "intelligence_emailq" => { query: "john@example.com" },
    "intelligence_ip" => { query: "test" },
    "intelligence_phone" => { query: "+33612345678" },
    "jobs" => { id: "test" },
    "vat" => { query: "test" },
    "vat_iban" => { query: "test" }
  }.freeze
end
