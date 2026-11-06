# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "veille"
require "json"
require "minitest/autorun"

# Records requests and answers with a configurable response.
class FakeTransport
  attr_reader :calls

  def initialize
    @calls = []
    @responder = -> { json_response({ "ok" => true }) }
  end

  def respond(&block)
    @responder = block
  end

  def call(method:, url:, headers:, body:, timeout:)
    @calls << { method: method, url: url, headers: headers, body: body, timeout: timeout }
    @responder.call
  end
end

def json_response(body, status = 200)
  [status, { "content-type" => ["application/json; charset=utf-8"] }, JSON.generate(body)]
end

def with_env(name, value)
  previous = ENV.fetch(name, nil)
  value.nil? ? ENV.delete(name) : ENV[name] = value
  yield
ensure
  previous.nil? ? ENV.delete(name) : ENV[name] = previous
end
