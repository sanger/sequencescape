# frozen_string_literal: true

# A schema as fetched by a Schemas::Source: its text, exactly as stored, its
# type, which decides the Schemas::Validator that checks payloads against
# it, and its version.
#
# @!attribute [r] text
#   @return [String] the schema text
# @!attribute [r] type
#   @return [Symbol] one of TYPES
# @!attribute [r] version
#   @return [Integer] the version, resolved when the latest was asked for
Schemas::Schema = Data.define(:text, :type, :version)

# The schema types: JSON Schema and Avro
Schemas::Schema::TYPES = %i[json_schema avro].freeze
