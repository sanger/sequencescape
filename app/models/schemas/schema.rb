# frozen_string_literal: true

# A schema as fetched by a Schemas::Source: its text, exactly as stored, and
# its type, which decides the Schemas::Validator that checks payloads
# against it.
#
# @!attribute [r] text
#   @return [String] the schema text
# @!attribute [r] type
#   @return [Symbol] one of TYPES
Schemas::Schema = Data.define(:text, :type)

# The schema types: JSON Schema and Avro
Schemas::Schema::TYPES = %i[json_schema avro].freeze
