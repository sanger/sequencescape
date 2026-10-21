# frozen_string_literal: true

# Reads schemas from files, in a folder for each schema type, then one for
# each subject, with one file for each version:
# <root>/json_schema/<subject>/<version>.json for JSON Schema, and
# <root>/avro/<subject>/<version>.avsc for Avro. The folder gives the type.
# Versions are whole numbers, as in a schema registry, so the latest is the
# highest number.
class Schemas::LocalSource < Schemas::Source
  # The file extension for each schema type, whose folder is named after it
  TYPE_EXTENSIONS = { json_schema: '.json', avro: '.avsc' }.freeze

  # A file name that is a version number, such as 1 or 12
  VERSION_NAME = /\A[1-9]\d*\z/

  # @return [Pathname] the directory that holds the schema type folders
  attr_reader :root

  # @param root [Pathname, String] the directory that holds the schema type
  #   folders
  def initialize(root = Rails.root.join('config/schemas'))
    super()
    @root = Pathname(root)
  end

  # (see Schemas::Source#fetch)
  # @raise [RuntimeError] if the version is in more than one type folder
  def fetch(subject, version)
    version = latest_version(subject) if version == :latest
    type, path = schema_file(subject, version)
    Schemas::Schema.new(text: path.read, type: type, version: version)
  end

  private

  # Files not named by a version number, such as draft.json or v1.json, are
  # ignored.
  def latest_version(subject)
    versions =
      TYPE_EXTENSIONS.flat_map do |type, extension|
        subject_folder(type, subject).glob("*#{extension}")
          .filter_map { |path| version_number(path) }
      end
    raise NotFound, "No versions of #{subject} in #{root}" if versions.empty?

    versions.max
  end

  def version_number(path)
    name = path.basename(path.extname).to_s
    name.to_i if VERSION_NAME.match?(name)
  end

  def schema_file(subject, version)
    files =
      TYPE_EXTENSIONS.filter_map do |type, extension|
        path = subject_folder(type, subject).join("#{version}#{extension}")
        [type, path] if path.file?
      end
    location = "#{subject} version #{version} in #{root}"
    raise NotFound, "No file for #{location}" if files.empty?
    raise "More than one file for #{location}" if files.many?

    files.first
  end

  def subject_folder(type, subject)
    root.join(type.to_s, subject)
  end
end
