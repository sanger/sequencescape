# frozen_string_literal: true

# Reads schemas from files, one directory for each subject and one file for
# each version: <root>/<subject>/<version>.json for JSON Schema, or
# <root>/<subject>/<version>.avsc for Avro.
class Schemas::LocalSource < Schemas::Source
  # The schema type for each file extension
  EXTENSION_TYPES = { '.json' => :json_schema, '.avsc' => :avro }.freeze

  # @return [Pathname] the directory that holds the subject directories
  attr_reader :root

  # @param root [Pathname, String] the directory that holds the subject
  #   directories
  def initialize(root = Rails.root.join('config/schemas'))
    super()
    @root = Pathname(root)
  end

  # (see Schemas::Source#fetch)
  # @raise [RuntimeError] if the version has a file for each schema type
  def fetch(subject, version)
    path = schema_path(subject, version)
    Schemas::Schema.new(text: path.read, type: EXTENSION_TYPES[path.extname])
  end

  private

  def schema_path(subject, version)
    paths = candidate_paths(subject, version).select(&:file?)
    location = "#{subject} version #{version} in #{root}"
    raise NotFound, "No file for #{location}" if paths.empty?
    raise "More than one file for #{location}" if paths.many?

    paths.first
  end

  def candidate_paths(subject, version)
    EXTENSION_TYPES.keys.map do |extension|
      root.join(subject, "#{version}#{extension}")
    end
  end
end
