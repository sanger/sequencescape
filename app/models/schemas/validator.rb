# frozen_string_literal: true

# Checks payloads against a schema. Each schema type has its own subclass,
# which implements #validate.
class Schemas::Validator
  # @return [Schemas::Schema] the schema payloads are checked against
  attr_reader :schema

  # @param schema [Schemas::Schema] the schema to check payloads against
  def initialize(schema)
    @schema = schema
  end

  # Checks a payload against the schema.
  #
  # @param payload [Object] the parsed JSON payload
  # @return [Array<Hash>] the errors, each with a JSON pointer (:pointer)
  #   and a message (:detail); empty when the payload is valid
  def validate(payload)
    raise NotImplementedError, 'abstract method'
  end
end
