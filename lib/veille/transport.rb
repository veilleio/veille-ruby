# frozen_string_literal: true

require "net/http"
require "uri"

module Veille
  # Default transport on Net::HTTP. A custom transport is any object with
  # +call(method:, url:, headers:, body:, timeout:)+ returning +[status, headers, body]+,
  # where headers is a Hash of lower-cased names to arrays of values.
  class NetHTTPTransport
    def call(method:, url:, headers:, body:, timeout:)
      uri = URI(url)
      request = (method == "POST" ? Net::HTTP::Post : Net::HTTP::Get).new(uri)
      headers.each { |name, value| request[name] = value }
      request.body = body if body
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      if timeout
        http.open_timeout = timeout
        http.read_timeout = timeout
        http.write_timeout = timeout
      end
      response = http.start { |connection| connection.request(request) }
      [response.code.to_i, response.to_hash, response.body || ""]
    end
  end
end
