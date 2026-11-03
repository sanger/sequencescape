# frozen_string_literal: true

# Gives the validator for a schema: fetches the schema from a source, and
# picks the Schemas::Validator for the schema's type.
class Schemas::Provider
  # Raised when no validator exists for a schema's type
  class UnsupportedType < Schemas::Error
  end

  # Raised when the source setting doesn't name a known source
  class UnknownSource < Schemas::Error
  end

  # Raised when a version setting is neither latest nor a number
  class InvalidVersion < Schemas::Error
  end

  # Raised when a setting the chosen source needs isn't set
  class MissingSetting < Schemas::Error
  end

  # The validator for each schema type that has one
  VALIDATORS = { json_schema: Schemas::JsonSchemaValidator }.freeze

  # The source for each value of the sapio_schema_source setting
  SOURCES = {
    'local' => -> { Schemas::LocalSource.new },
    'redpanda' => -> { Schemas::RedpandaSource.new(registry_url) }
  }.freeze

  # @return [Schemas::Source] where schemas are fetched from
  attr_reader :source

  # A provider for the source named by the sapio_schema_source setting in
  # config/environments.
  #
  # @return [Schemas::Provider]
  # @raise [UnknownSource] if the setting doesn't name a known source
  # @raise [MissingSetting] if a setting the source needs isn't set
  def self.configured
    name = Rails.application.config.try(:sapio_schema_source)
    build = SOURCES.fetch(name) do
      raise UnknownSource, "Unknown schema source: #{name.inspect}"
    end
    new(build.call)
  end

  # Converts a version setting, which can come from an environment
  # variable, to a version: 'latest' to :latest, and '3' to 3.
  #
  # @param value [String, Integer] the setting
  # @return [Integer, :latest] the version
  # @raise [InvalidVersion] if the value is neither latest nor a number
  def self.parse_version(value)
    return :latest if value.to_s == 'latest'

    Integer(value.to_s, 10)
  rescue ArgumentError
    raise InvalidVersion, "Not a schema version: #{value.inspect}"
  end

  # @return [String] the sapio_schema_registry_url setting
  # @raise [MissingSetting] if it isn't set
  def self.registry_url
    url = Rails.application.config.try(:sapio_schema_registry_url)
    return url if url.present?

    raise MissingSetting, 'sapio_schema_registry_url is not set'
  end
  private_class_method :registry_url

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
    schema = source.fetch(subject, version)
    validator = VALIDATORS.fetch(schema.type) do
      raise UnsupportedType, "No validator for #{schema.type} schemas"
    end
    Rails.logger.info("Using schema #{subject} version #{schema.version}")
    validator.new(schema)
  end
end
