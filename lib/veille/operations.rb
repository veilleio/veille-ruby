# frozen_string_literal: true

# Generated from the Veille OpenAPI document. Do not edit by hand.

module Veille
  # One method per documented endpoint. Mixed into {Client}.
  module Operations
    # Domain Validation. Check any domain instantly. Detects disposable email providers, public webmail, relay services, and education domains. Returns DNS health with MX provider detection, domain history, and optional SSL/TLS certificate transparency. Credit cost: 2 credits per call.
    #
    # +GET /v1/intelligence/domain+
    #
    # @param query [String] (required) The domain to validate. Accepts raw domains (tempmail.org), full URLs (https://www.tempmail.org/page), or domains with www. prefix, all are normalized automatically.
    # @param certificate_transparency [Boolean] Enable Certificate Transparency lookup. Returns SSL/TLS certificate history, current certificate, issuers, and all Subject Alternative Names (SANs) ever associated with the domain. Adds 1-5 seconds o…
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def intelligence_domain(request_options: nil, **params)
      call_operation("intelligence_domain", params, request_options)
    end

    # Email Validation. Validate any email address in a single call. Detects disposable and temporary inboxes, identifies role accounts, public webmail, relay services, and returns a 0-100 risk score. For deep deliverability verification (SMTP check, catch-all de… Credit cost: 3 credits per call.
    #
    # +GET /v1/intelligence/email+
    #
    # @param query [String] (required) The email address to validate (e.g. john@example.com). Automatically normalized to lowercase.
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def intelligence_email(request_options: nil, **params)
      call_operation("intelligence_email", params, request_options)
    end

    # Email Qualification. Deep email deliverability verification. Performs full Email Validation plus SMTP inbox check, catch-all detection, and returns a qualification verdict (valid, invalid, risky, disposable, unknown). Credit cost: 5 credits per call.
    #
    # +GET /v1/intelligence/emailq+
    #
    # @param query [String] (required) The email address to qualify (e.g. john@example.com). Automatically normalized to lowercase.
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def intelligence_emailq(request_options: nil, **params)
      call_operation("intelligence_emailq", params, request_options)
    end

    # IP Reputation. Assess the reputation of any IP address. Detects VPNs, proxies, Tor exit nodes, datacenter hosting, abusive traffic, and bots. Returns geolocation, network owner, and a 0-100 threat score. Credit cost: 2 credits per call.
    #
    # +GET /v1/intelligence/ip+
    #
    # @param query [String] (required) The IP address to analyze (IPv4 or IPv6).
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def intelligence_ip(request_options: nil, **params)
      call_operation("intelligence_ip", params, request_options)
    end

    # Phone Validation. Validate any phone number in E.164 format. Detects disposable and virtual numbers, identifies carrier and line type (mobile/fixed/VoIP), returns country and timezone, and computes a 0-100 risk score. Credit cost: 1 credit per call.
    #
    # +GET /v1/intelligence/phone+
    #
    # @param query [String] (required) The phone number to validate in E.164 format (must start with +, e.g. +33612345678).
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def intelligence_phone(request_options: nil, **params)
      call_operation("intelligence_phone", params, request_options)
    end

    # Jobs. Poll the status, progress (0–100) and result of a job started with is_async=true. Polling is free. Poll until status is terminal: CompletedJob, Error, NotFound or BadRequest.
    #
    # +GET /v1/jobs/{id}+
    #
    # @param id [String] (required) The job_id returned by an endpoint called with is_async=true.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def jobs(request_options: nil, **params)
      call_operation("jobs", params, request_options)
    end

    # Stats. Infrastructure health for an engine or endpoint over the last hour. Not scoped to your account or tenant. Enabled per account: HTTP 403 means contact support to activate it.
    #
    # +GET /v1/stats+
    #
    # @param engine [String] API family to check, for example vat. Provide at least engine or path.
    # @param path [String] Specific endpoint to check, for example /v1/vat. If you also pass engine, use an endpoint from that API.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def stats(request_options: nil, **params)
      call_operation("stats", params, request_options)
    end

    # Usage. Retrieve real-time usage statistics and credit balance for your Veille account.
    #
    # +GET /v1/usage+
    #
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def usage(request_options: nil, **params)
      call_operation("usage", params, request_options)
    end

    # VAT Validation. Validate a European VAT number against the VIES database. Returns company name, registered address, and validity status for any EU member state. Credit cost: 1 credit per call.
    #
    # +GET /v1/vat+
    #
    # @param query [String] (required) The VAT number to validate (e.g. FR40303265045).
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def vat(request_options: nil, **params)
      call_operation("vat", params, request_options)
    end

    # IBAN Validation. Validate any IBAN and retrieve associated bank details. Returns the BIC/SWIFT code, bank name, country, BBAN structural breakdown, and SEPA zone membership. Credit cost: 1 credit per call.
    #
    # +GET /v1/vat/iban+
    #
    # @param query [String] (required) The IBAN to validate (e.g. FR7630006000011234567890189).
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def vat_iban(request_options: nil, **params)
      call_operation("vat_iban", params, request_options)
    end

    # Exchange Rates. Get current ECB exchange rates for any supported base currency. Optionally filter to specific target currencies. Updated daily from the European Central Bank. Credit cost: 1 credit per call.
    #
    # +GET /v1/vat/rates+
    #
    # @param base [String] Base currency ISO 4217 code (defaults to EUR).
    # @param symbols [String] Comma-separated target currency codes to filter (e.g. USD,GBP,JPY).
    # @param fields [String] Comma-separated list of fields to keep in the response, with dot notation for nested fields (e.g. name,location.city). Does not change the credit cost.
    # @param is_async [Boolean] Process the request asynchronously: the response is a job_id to poll on /v1/jobs/{id} (see waitForJob).
    # @param soft_fail [Boolean] Return HTTP 200 even when an error occurs; the error is then in the response body.
    # @param request_options [Hash, nil] +:method+ ("GET"/"POST"), +:timeout+ (seconds), +:headers+
    # @return [JsonResponse]
    def vat_rates(request_options: nil, **params)
      call_operation("vat_rates", params, request_options)
    end
  end
end
