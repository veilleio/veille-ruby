# frozen_string_literal: true

# Generated from the Veille OpenAPI document. Do not edit by hand.

module Veille
  # Path, methods, response kind and parameter names of every documented operation.
  ENDPOINTS = {
    "intelligence_domain" => {
      path: "/v1/intelligence/domain",
      methods: ["GET"].freeze,
      response: :json,
      required: ["query"].freeze,
      params: ["query", "certificate_transparency", "fields", "is_async", "soft_fail"].freeze
    }.freeze,
    "intelligence_email" => {
      path: "/v1/intelligence/email",
      methods: ["GET"].freeze,
      response: :json,
      required: ["query"].freeze,
      params: ["query", "fields", "is_async", "soft_fail"].freeze
    }.freeze,
    "intelligence_emailq" => {
      path: "/v1/intelligence/emailq",
      methods: ["GET"].freeze,
      response: :json,
      required: ["query"].freeze,
      params: ["query", "fields", "is_async", "soft_fail"].freeze
    }.freeze,
    "intelligence_ip" => {
      path: "/v1/intelligence/ip",
      methods: ["GET"].freeze,
      response: :json,
      required: ["query"].freeze,
      params: ["query", "fields", "is_async", "soft_fail"].freeze
    }.freeze,
    "intelligence_phone" => {
      path: "/v1/intelligence/phone",
      methods: ["GET"].freeze,
      response: :json,
      required: ["query"].freeze,
      params: ["query", "fields", "is_async", "soft_fail"].freeze
    }.freeze,
    "jobs" => {
      path: "/v1/jobs/{id}",
      methods: ["GET"].freeze,
      response: :json,
      required: ["id"].freeze,
      params: ["id"].freeze
    }.freeze,
    "stats" => {
      path: "/v1/stats",
      methods: ["GET"].freeze,
      response: :json,
      required: [].freeze,
      params: ["engine", "path"].freeze
    }.freeze,
    "usage" => {
      path: "/v1/usage",
      methods: ["GET"].freeze,
      response: :json,
      required: [].freeze,
      params: [].freeze
    }.freeze,
    "vat" => {
      path: "/v1/vat",
      methods: ["GET"].freeze,
      response: :json,
      required: ["query"].freeze,
      params: ["query", "fields", "is_async", "soft_fail"].freeze
    }.freeze,
    "vat_iban" => {
      path: "/v1/vat/iban",
      methods: ["GET"].freeze,
      response: :json,
      required: ["query"].freeze,
      params: ["query", "fields", "is_async", "soft_fail"].freeze
    }.freeze,
    "vat_rates" => {
      path: "/v1/vat/rates",
      methods: ["GET"].freeze,
      response: :json,
      required: [].freeze,
      params: ["base", "symbols", "fields", "is_async", "soft_fail"].freeze
    }.freeze
  }.freeze
end
