# frozen_string_literal: true

require "json"
require "veille"

client = Veille::Client.new # reads VEILLE_API_KEY
response = client.intelligence_email(query: "jane.doe@example.com")
puts JSON.pretty_generate(response.data)
