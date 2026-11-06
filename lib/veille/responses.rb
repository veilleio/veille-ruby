# frozen_string_literal: true

module Veille
  # Buffered HTTP response: status, lower-cased multi-value headers, content type and body bytes.
  RawResponse = Struct.new(:status, :headers, :content_type, :body, keyword_init: true)

  # Outcome of one Client#batch item: +value+ when +ok?+, else +error+.
  BatchResult = Struct.new(:index, :value, :error, keyword_init: true) do
    def ok? = error.nil?
  end

  # A successful JSON response; +data+ is the parsed body (string keys).
  class JsonResponse
    attr_reader :data, :raw_response

    def initialize(data:, raw_response:)
      @data = data
      @raw_response = raw_response
    end

    def kind = :json
    def json? = true
    def binary? = false
  end

  # A successful non-JSON response (image, PDF, HTML…).
  class BinaryResponse
    attr_reader :bytes, :content_type, :raw_response

    def initialize(bytes:, content_type:, raw_response:)
      @bytes = bytes
      @content_type = content_type
      @raw_response = raw_response
    end

    def kind = :binary
    def json? = false
    def binary? = true

    # Writes the body to +path+ and returns the number of bytes written.
    def save(path)
      File.binwrite(path, bytes)
    end
  end
end
