# frozen_string_literal: true

module Veille
  # Base class for every SDK-defined error.
  class Error < StandardError; end

  # The client configuration is missing or unusable.
  class ConfigurationError < Error; end

  # A request value cannot be represented safely on the wire.
  class SerializationError < Error
    attr_reader :param

    def initialize(message, param = nil)
      super(message)
      @param = param
    end
  end

  # The request failed before a complete HTTP response was received.
  class TransportError < Error; end

  # Veille returned a non-success HTTP status.
  class APIError < Error
    attr_reader :status, :error_message, :response_body, :raw_response

    def initialize(raw_response:, response_body: nil, error_message: nil)
      super(error_message || "Veille API request failed with status #{raw_response.status}.")
      @status = raw_response.status
      @error_message = error_message
      @response_body = response_body
      @raw_response = raw_response
    end
  end

  # A successful response could not be decoded as the documented representation.
  class ResponseDecodingError < Error
    attr_reader :raw_response

    def initialize(message, raw_response)
      super(message)
      @raw_response = raw_response
    end
  end

  # An async job did not reach a terminal status before the deadline.
  class JobTimeoutError < Error
    attr_reader :job_id, :last_response

    def initialize(job_id, last_response = nil)
      super("Job #{job_id} did not finish before the deadline.")
      @job_id = job_id
      @last_response = last_response
    end
  end
end
