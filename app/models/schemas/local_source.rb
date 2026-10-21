# frozen_string_literal: true

# Reads schemas from files, one directory for each subject and one file for
# each version: <root>/<subject>/<version>.json for JSON Schema, or
# <root>/<subject>/<version>.avsc for Avro. Versions are whole numbers, as
# in a schema registry, so the latest is the highest number.
class Schemas::LocalSource < Schemas::Source
  # The schema type for each file extension
  EXTENSION_TYPES = { '.json' => :json_schema, '.avsc' => :avro }.freeze

  # A file name that is a version number, such as 1 or 12
  VERSION_NAME = /\A[1-9]\d*\z/

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
    version = latest_version(subject) if version == :latest
    path = schema_path(subject, version)
    Schemas::Schema.new(text: path.read,
                        type: EXTENSION_TYPES[path.extname],
                        version: version)
  end

  private

  # Files not named by a version number, such as draft.json or v1.json, are
  # ignored.
  def latest_version(subject)
    versions = schema_files(subject).filter_map do |path|
      name = path.basename(path.extname).to_s
      name.to_i if VERSION_NAME.match?(name)
    end
    raise NotFound, "No versions of #{subject} in #{root}" if versions.empty?

    versions.max
  end

  def schema_files(subject)
    root.join(subject).glob("*{#{EXTENSION_TYPES.keys.join(',')}}")
  end

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
