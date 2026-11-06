# Examples

```sh
gem install veille
export VEILLE_API_KEY="YOUR_API_KEY"
ruby examples/json.rb
```

- `json.rb` — call the featured endpoint and print the JSON result.
- `request.rb` — call any path with `request` and handle API errors.
- `wait_for_job.rb` — start an async job and wait for its result.
