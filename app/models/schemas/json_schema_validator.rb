# frozen_string_literal: true

# Checks payloads against a JSON Schema, using json_schemer. The JSON
# Schema version (draft) comes from the schema's $schema keyword, and
# 2020-12 is used when it has none. Formats, such as uuid, are checked, and
# remote references are not fetched.
class Schemas::JsonSchemaValidator < Schemas::Validator
  # Raised when the schema isn't JSON, or isn't valid for its draft, as a
  # schema that isn't valid can accept every payload
  class InvalidSchema < Schemas::Error
  end

  # @param schema [Schemas::Schema] a JSON Schema
  # @raise [InvalidSchema] if the schema isn't JSON or isn't valid
  def initialize(schema)
    super
    @schemer = JSONSchemer.schema(parse(schema.text))
    return if @schemer.valid_schema?

    raise InvalidSchema, 'The schema is not a valid JSON Schema.'
  end

  # (see Schemas::Validator#validate)
  # A missing required property is reported against the object that
  # lacks it.
  def validate(payload)
    @schemer.validate(payload).map do |error|
      { pointer: error['data_pointer'], detail: error['error'] }
    end
  end

  private

  def parse(text)
    JSON.parse(text)
  rescue JSON::ParserError
    raise InvalidSchema, 'The schema is not JSON.'
  end
end
