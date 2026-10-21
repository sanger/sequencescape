# frozen_string_literal: true

# Gives the validator for a schema: fetches the schema from a source, and
# picks the Schemas::Validator for the schema's type.
class Schemas::Provider
  # Raised when no validator exists for a schema's type
  class UnsupportedType < StandardError
  end

  # The validator for each schema type that has one
  VALIDATORS = { json_schema: Schemas::JsonSchemaValidator }.freeze

  # @param source [Schemas::Source] where schemas are fetched from
  def initialize(source)
    @source = source
  end

  # Fetches a schema and gives a validator for it. Logs the subject and the
  # version used, which is resolved when the latest is asked for.
  #
  # @param subject [String] the schema's name
  # @param version [Integer, :latest] the schema's version
  # @return [Schemas::Validator] a validator for the schema
  # @raise [Schemas::Source::NotFound] if the source doesn't hold it
  # @raise [UnsupportedType] if no validator exists for the schema's type
  def validator_for(subject:, version:)
    schema = @source.fetch(subject, version)
    validator = VALIDATORS.fetch(schema.type) do
      raise UnsupportedType, "No validator for #{schema.type} schemas"
    end
    Rails.logger.info("Using schema #{subject} version #{schema.version}")
    validator.new(schema)
  end
end
