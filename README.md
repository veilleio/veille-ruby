# Veille Ruby SDK

The official Ruby SDK for the [Veille](https://www.veille.io) fraud prevention API.

Validate emails, domains, IPs, VAT numbers and IBANs in milliseconds to block fake sign-ups, bots and fraud.

The SDK exposes **11 methods**, one per documented endpoint, plus a generic `request`. It only uses the Ruby standard library.

## Requirements

- Ruby 3.1 or newer

## Installation

```sh
gem install veille
```

Or in your `Gemfile`:

```ruby
gem "veille"
```

## Get your API key

[Sign up for Veille](https://app.veille.io/register) or sign in, then copy your API key from the [dashboard](https://app.veille.io). The client reads `ENV["VEILLE_API_KEY"]` when no key is passed.

## Quick start

```ruby
require "veille"

client = Veille::Client.new(api_key: ENV.fetch("VEILLE_API_KEY"))
response = client.intelligence_email(query: "jane.doe@example.com")
puts response.data
```

Keyword arguments use the parameter names of the [API reference](https://app.veille.io/openapi). Unknown names raise `Veille::SerializationError`; use `request` for undocumented parameters.

## Async jobs

Any call accepts `is_async: true` (useful past the 60-second server limit): the response is then a `job_id`. `wait_for_job` polls `GET /v1/jobs/{id}` until a terminal status (`CompletedJob`, `Error`, `NotFound`, `BadRequest`):

```ruby
submitted = client.intelligence_email(query: "jane.doe@example.com", is_async: true)
job = client.wait_for_job(submitted.data["job_id"]) { |j| puts "#{j['status']} #{j['progress']}%" }
puts job.data
```

## GET or POST

Methods use GET when the endpoint supports it (query string). POST sends the same parameters as JSON:

`nil` values are omitted, `false` and `0` are sent, and arrays repeat the parameter name.

## Any endpoint

```ruby
response = client.request("GET", "/v1/usage")
```

## Errors

```ruby
begin
  client.intelligence_email(query: "jane.doe@example.com")
rescue Veille::APIError => e
  warn "HTTP #{e.status}: #{e.message}"
end
```

| Error | When |
| --- | --- |
| `Veille::ConfigurationError` | Missing API key, invalid options or unsupported method. |
| `Veille::SerializationError` | A required parameter is missing, unknown or can't be sent. |
| `Veille::TransportError` | Network failure or timeout. |
| `Veille::APIError` | Non-2xx status (`status`, `error_message`, `response_body`, `raw_response`). |
| `Veille::ResponseDecodingError` | A success response could not be decoded. |

All of them inherit from `Veille::Error`.

## Retries

Requests are retried up to 3 times after a network error, a `408`, `500`, `502`, `503` or `504`, or a rate limit — which the API returns as `401` (or `429`) with a `Rate limit exceeded` message. Per-key quota errors (`…: quota daily`) are not retried, nor are `400`, `402`, `404` or client-side timeouts. The delay starts at 1 second and grows 1.5× per retry (capped at 30 seconds); a `Retry-After` header wins.

```ruby
client = Veille::Client.new(max_retries: 5, retry_delay: 0.5)
client.intelligence_email(query: "jane.doe@example.com", request_options: { max_retries: 0 }) # one request without retries
```

## Batch requests

`batch` runs the block for every item on 10 threads (`concurrency:`) and returns one `BatchResult` per item, in input order. A failing item never stops the others.

```ruby
inputs = ["jane.doe@example.com", "john@mailinator.com", "contact@veille.io"]
results = client.batch(inputs, concurrency: 5) { |value| client.intelligence_email(query: value) }
results.each do |result|
  if result.ok?
    puts result.value.data
  else
    warn "#{inputs[result.index]}: #{result.error.message}"
  end
end
```

| Constant | Default | Description |
| --- | --- | --- |
| `Veille::Client::DEFAULT_CONCURRENCY` | `10` | Tasks run at the same time by batch |
| `Veille::Client::DEFAULT_TIMEOUT` | `120` | Request timeout (seconds) |
| `Veille::Client::MAX_RETRIES` | `3` | Retry attempts after a network error, a 408/5xx or a rate limit |
| `Veille::Client::RETRY_BACKOFF_FACTOR` | `1.5` | Exponential backoff multiplier |
| `Veille::Client::DEFAULT_RETRY_DELAY` | `1.0` | Delay before the first retry (seconds) |

## Timeouts and custom transports

```ruby
client = Veille::Client.new(timeout: 60) # seconds, default 120
client.intelligence_email(query: "jane.doe@example.com", request_options: { timeout: 30 })
```

A transport is any object with `call(method:, url:, headers:, body:, timeout:)` returning `[status, headers, body]`; the default is `Veille::NetHTTPTransport`.

## Endpoints

11 methods, generated from the [OpenAPI document](https://app.veille.io/openapi).

| Method | HTTP | Description |
| --- | --- | --- |
| `intelligence_domain` | GET `/v1/intelligence/domain` | Check any domain instantly. Detects disposable email providers, public webmail, relay services, and education domains. Returns DNS health w… |
| `intelligence_email` | GET `/v1/intelligence/email` | Validate any email address in a single call. Detects disposable and temporary inboxes, identifies role accounts, public webmail, relay serv… |
| `intelligence_emailq` | GET `/v1/intelligence/emailq` | Deep email deliverability verification. Performs full Email Validation plus SMTP inbox check, catch-all detection, and returns a qualificat… |
| `intelligence_ip` | GET `/v1/intelligence/ip` | Assess the reputation of any IP address. Detects VPNs, proxies, Tor exit nodes, datacenter hosting, abusive traffic, and bots. Returns geol… |
| `intelligence_phone` | GET `/v1/intelligence/phone` | Validate any phone number in E.164 format. Detects disposable and virtual numbers, identifies carrier and line type (mobile/fixed/VoIP), re… |
| `jobs` | GET `/v1/jobs/{id}` | Poll the status, progress (0–100) and result of a job started with is_async=true. Polling is free. Poll until status is terminal: Completed… |
| `stats` | GET `/v1/stats` | Infrastructure health for an engine or endpoint over the last hour. Not scoped to your account or tenant. Enabled per account: HTTP 403 mea… |
| `usage` | GET `/v1/usage` | Retrieve real-time usage statistics and credit balance for your Veille account. |
| `vat` | GET `/v1/vat` | Validate a European VAT number against the VIES database. Returns company name, registered address, and validity status for any EU member s… |
| `vat_iban` | GET `/v1/vat/iban` | Validate any IBAN and retrieve associated bank details. Returns the BIC/SWIFT code, bank name, country, BBAN structural breakdown, and SEPA… |
| `vat_rates` | GET `/v1/vat/rates` | Get current ECB exchange rates for any supported base currency. Optionally filter to specific target currencies. Updated daily from the Eur… |

## License

MIT — see [LICENSE](LICENSE).
