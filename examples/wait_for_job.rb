# frozen_string_literal: true

require "veille"

client = Veille::Client.new # reads VEILLE_API_KEY
submitted = client.intelligence_email(query: "jane.doe@example.com", is_async: true)
job = client.wait_for_job(submitted.data["job_id"]) { |j| puts "#{j['status']} #{j['progress']}%" }
puts job.data
