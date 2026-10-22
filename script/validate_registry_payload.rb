# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'json_schemer'

# Example usage
# 1. Run redpanda schema registry locally: docker run -ti -p 9092:9092 -p 8081:8081 redpandadata/redpanda
# 2. Post the example work order schema to redpanda:
#     jq -Rs '{schema: ., schemaType: "JSON"}' < example-work-order-schema-v0.2.json |
#       curl -X POST "http://localhost:8081/subjects/work-order-schema/versions" \
#         -H 'Content-Type: application/vnd.schemaregistry.v1+json' \
#         --data-binary @-
# 3. Validate a payload against the registered schema:
#     bundle exec ruby script/validate_registry_payload.rb work-order-schema example-payload.json 1
#
def usage
  warn 'Usage: bundle exec ruby script/validate_registry_payload.rb SUBJECT PAYLOAD.json [VERSION]'
  warn 'Set SCHEMA_REGISTRY_URL to the registry subjects endpoint (default: http://localhost:8081/subjects).'
  warn 'Optional credentials: SCHEMA_REGISTRY_USERNAME and SCHEMA_REGISTRY_PASSWORD.'
  exit 2
end

subject, payload_path, version = ARGV
usage unless subject && payload_path && ARGV.length <= 3

def validate_payload(subject, payload_path, version) # rubocop:disable Metrics/AbcSize
  registry_url = ENV.fetch('SCHEMA_REGISTRY_URL', 'http://localhost:8081/subjects').sub(%r{/+$}, '')
  encoded_subject = URI.encode_www_form_component(subject)
  uri = URI("#{registry_url}/#{encoded_subject}/versions/#{version}")
  request = Net::HTTP::Get.new(uri)

  username = ENV.fetch('SCHEMA_REGISTRY_USERNAME', nil)
  password = ENV.fetch('SCHEMA_REGISTRY_PASSWORD', nil)
  request.basic_auth(username, password) if username && password

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end
  abort "Schema Registry returned HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

  registry_entry = JSON.parse(response.body)
  schema_type = registry_entry['schemaType']
  abort "Expected a JSON Schema, but registry returned #{schema_type}" if schema_type && schema_type != 'JSON'

  schema = JSON.parse(registry_entry.fetch('schema'))
  payload_source = File.read(payload_path)
  payload = JSON.parse(payload_source)
  errors = JSONSchemer.schema(schema, format: true).validate(payload).to_a

  if errors.empty?
    puts "Valid against #{subject} version #{registry_entry['version'] || version} (schema id #{registry_entry['id']})."
  else
    warn "Invalid against #{subject} version #{registry_entry['version'] || version}:"
    errors.each do |error|
      pointer = error['data_pointer'].empty? ? '#' : "##{error['data_pointer']}"
      warn "  #{pointer}: #{error['error']}"
    end
    exit 1
  end
rescue JSON::ParserError => e
  abort "Invalid JSON: #{e.message}"
rescue KeyError => e
  abort "Unexpected Schema Registry response (missing #{e.key.inspect})."
end

validate_payload(subject, payload_path, version || 'latest')
