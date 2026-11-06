# frozen_string_literal: true

require "veille"

client = Veille::Client.new # reads VEILLE_API_KEY
begin
  response = client.request("GET", "/v1/usage")
  puts response.data if response.json?
rescue Veille::APIError => e
  warn "HTTP #{e.status}: #{e.message}"
end
