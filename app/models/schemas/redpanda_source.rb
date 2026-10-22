# frozen_string_literal: true

# Reads schemas from a schema registry with the Confluent API, such as
# Redpanda's. The registry records each version's type as its schemaType:
# JSON for JSON Schema, and none for Avro.
class Schemas::RedpandaSource < Schemas::Source
  # The schema type for each registry schemaType that has a validator type
  REGISTRY_TYPES = { nil => :avro, 'AVRO' => :avro, 'JSON' => :json_schema }
    .freeze

  # @param url [String] the registry's base URL, without /subjects
  def initialize(url)
    super()
    @client = HTTPClients::SchemaRegistryClient.new(url)
  end

  # (see Schemas::Source#fetch)
  # @raise [Unavailable] if the registry can't be reached, takes too long or
  #   answers with an error
  # @raise [Schemas::Provider::UnsupportedType] for a type such as Protobuf
  def fetch(subject, version)
    answer = @client.schema_version(subject, version)
    Schemas::Schema.new(text: answer['schema'], type: type_of(answer),
                        version: answer['version'])
  rescue Faraday::ResourceNotFound
    raise NotFound, "No #{subject} version #{version} in the schema registry"
  rescue Faraday::Error => e
    raise Unavailable, "The schema registry is unavailable: #{e.message}"
  end

  private

  def type_of(answer)
    schema_type = answer['schemaType']
    REGISTRY_TYPES.fetch(schema_type) do
      raise Schemas::Provider::UnsupportedType,
            "No validator for #{schema_type} schemas"
    end
  end
end
