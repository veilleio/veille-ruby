# frozen_string_literal: true

require "json"
require "uri"

module Veille
  # Request serialization: path filling, query pairs and JSON bodies.
  module Serialization
    QUERY_STRING_PARAMS = %w[fields is_async soft_fail].freeze

    module_function

    # Fills {name} path segments, then returns [path, query_pairs, body].
    # nil values are omitted; false and 0 are sent.
    def serialize(method, path_template, params)
      raise SerializationError, "Request parameters must be a Hash." unless params.nil? || params.is_a?(Hash)

      remaining = {}
      (params || {}).each { |name, value| remaining[name.to_s] = value unless value.nil? }
      path = path_template.gsub(/\{([^}]+)\}/) do
        name = Regexp.last_match(1)
        raise SerializationError.new("The \"#{name}\" path parameter is required.", name) unless remaining.key?(name)

        URI.encode_www_form_component(wire_string(name, remaining.delete(name))).gsub("+", "%20")
      end

      if method == "POST"
        # The API reads the global parameters from the query string, whatever the method.
        globals = QUERY_STRING_PARAMS.filter_map { |name| [name, wire_string(name, remaining.delete(name))] if remaining.key?(name) }
        return [path, globals, remaining]
      end

      pairs = []
      remaining.each do |name, value|
        if value.is_a?(Array)
          value.each { |item| pairs << [name, wire_string(name, item)] unless item.nil? }
        else
          pairs << [name, wire_string(name, value)]
        end
      end
      [path, pairs, nil]
    end

    def wire_string(name, value)
      case value
      when String then value
      when true, false, Integer, Symbol then value.to_s
      when Float
        raise SerializationError.new("The \"#{name}\" parameter must be a finite number.", name) unless value.finite?

        value == value.floor ? value.to_i.to_s : value.to_s
      when Hash, Array then JSON.generate(value)
      else
        raise SerializationError.new("The \"#{name}\" parameter has an unsupported type (#{value.class}).", name)
      end
    end

    def encode_query(pairs)
      pairs.map { |name, value| "#{escape(name)}=#{escape(value)}" }.join("&")
    end

    def escape(value)
      URI.encode_www_form_component(value).gsub("+", "%20")
    end
  end
end
