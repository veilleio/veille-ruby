# frozen_string_literal: true

require_relative "lib/veille/version"

Gem::Specification.new do |spec|
  spec.name = "veille"
  spec.version = Veille::VERSION
  spec.authors = ["Veille"]
  spec.email = ["contact@veille.io"]

  spec.summary = "Official Ruby SDK for the Veille fraud prevention API."
  spec.description = "Validate emails, domains, IPs, VAT numbers and IBANs in milliseconds to block fake sign-ups, bots and fraud."
  spec.homepage = "https://www.veille.io"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/veilleio/veille-ruby/issues",
    "documentation_uri" => "https://app.veille.io/openapi",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/veilleio/veille-ruby"
  }

  spec.files = Dir["LICENSE", "README.md", "examples/**/*", "lib/**/*.rb", "sig/**/*.rbs"]
  spec.require_paths = ["lib"]
end
