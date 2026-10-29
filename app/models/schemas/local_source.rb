# frozen_string_literal: true

# Reads schemas from files, in a folder for each subject, with one file for
# each version: <root>/<subject>/<version>.json for JSON Schema, and
# <root>/<subject>/<version>.avsc for Avro. The extension gives the type.
# As in a schema registry, versions are whole numbers, so the latest is the
# highest number, and all versions of a subject have the same type.
class Schemas::LocalSource < Schemas::Source
  # The file extension for each schema type
  TYPE_EXTENSIONS = { json_schema: '.json', avro: '.avsc' }.freeze

  # A file name that is a version number, such as 1 or 12
  VERSION_NAME = /\A[1-9]\d*\z/

  # Raised when a subject has versions of more than one type
  class MixedTypes < Schemas::Error
  end

  # @return [Pathname] the directory that holds the subject folders
  attr_reader :root

  # @param root [Pathname, String] the directory that holds the subject
  #   folders
  def initialize(root = Rails.root.join('config/schemas'))
    super()
    @root = Pathname(root)
  end

  # (see Schemas::Source#fetch)
  # @raise [MixedTypes] if the subject has versions of more than one type
  def fetch(subject, version)
    type = subject_type(subject)
    version = latest_version(type, subject) if version == :latest
    path = subject_folder(subject).join(file_name(type, version))
    location = "#{subject} version #{version} in #{root}"
    raise NotFound, "No file for #{location}" unless path.file?

    Schemas::Schema.new(text: path.read, type: type, version: version)
  end

  private

  # A schema registry rejects a version whose type differs from the
  # subject's earlier versions, so a subject with versions of more than one
  # type is an error.
  def subject_type(subject)
    types = TYPE_EXTENSIONS.keys.select do |type|
      version_files(type, subject).any?
    end
    raise NotFound, "No versions of #{subject} in #{root}" if types.empty?

    message = "#{subject} has more than one schema type in #{root}"
    raise MixedTypes, message if types.many?

    types.first
  end

  def latest_version(type, subject)
    version_files(type, subject).map { |path| version_name(type, path).to_i }
      .max
  end

  # The files named by a version number. Others, such as draft.json or
  # v1.json, are ignored.
  def version_files(type, subject)
    subject_folder(subject).glob("*#{TYPE_EXTENSIONS[type]}")
      .select do |path|
        path.file? && VERSION_NAME.match?(version_name(type, path))
      end
  end

  def version_name(type, path)
    path.basename(TYPE_EXTENSIONS[type]).to_s
  end

  def file_name(type, version)
    "#{version}#{TYPE_EXTENSIONS[type]}"
  end

  def subject_folder(subject)
    root.join(subject)
  end
end
