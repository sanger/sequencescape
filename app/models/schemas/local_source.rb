# frozen_string_literal: true

# Reads schemas from files, in a folder for each subject, with one file for
# each version: <root>/<subject>/<version>.json for JSON Schema, and
# <root>/<subject>/<version>.avsc for Avro. The extension gives the type.
# As in a schema registry, versions are whole numbers, so the latest is the
# highest number, and all versions of a subject have the same type.
#
# The next version can be worked on as a work in progress (WIP), as record
# loaders' .wip.yml files are: <root>/<subject>/<version>.wip.json. A WIP
# file is read only when the source is made with wip: true; otherwise it is
# ignored. When it is agreed, it is renamed to <version>.json.
class Schemas::LocalSource < Schemas::Source
  # The file extension for each schema type
  TYPE_EXTENSIONS = { json_schema: '.json', avro: '.avsc' }.freeze

  # A file name that is a version number, such as 1 or 12
  VERSION_NAME = /\A[1-9]\d*\z/

  # A WIP file name: a version number, then .wip, such as 2.wip; the number
  # is captured
  WIP_NAME = /\A([1-9]\d*)\.wip\z/

  # Raised when a subject has versions of more than one type
  class MixedTypes < Schemas::Error
  end

  # Raised when a version has both a file and a WIP file, such as 2.json
  # and 2.wip.json: a WIP left behind after it was renamed
  class DuplicateVersion < Schemas::Error
  end

  # @return [Pathname] the directory that holds the subject folders
  attr_reader :root

  # @param root [Pathname, String] the directory that holds the subject
  #   folders
  # @param wip [Boolean] whether WIP files are read
  def initialize(root = Rails.root.join('config/schemas'), wip: false)
    super()
    @root = Pathname(root)
    @wip = wip
  end

  # (see Schemas::Source#fetch)
  # @raise [MixedTypes] if the subject has versions of more than one type
  # @raise [DuplicateVersion] if a version has both a file and a WIP file
  def fetch(subject, version)
    type = subject_type(subject)
    files = version_files(type, subject)
    version = files.keys.max if version == :latest
    path = files[version]
    location = "#{subject} version #{version} in #{root}"
    raise NotFound, "No file for #{location}" unless path

    Schemas::Schema.new(text: path.read, type: type, version: version,
                        wip: wip_name?(type, path))
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

  # The subject's files of the type, by version number: those named by a
  # version number, and WIP files when they are read. Others, such as
  # draft.json or v1.json, are ignored.
  def version_files(type, subject)
    subject_folder(subject).glob("*#{TYPE_EXTENSIONS[type]}").select(&:file?)
      .each_with_object({}) do |path, files|
        version = version_number(type, path)
        next unless version

        check_duplicate(subject, version, files[version], path)
        files[version] = path
      end
  end

  # The version a file is for, or nil if it isn't one: a file named by
  # neither a version number nor, when WIP files are read, a WIP name.
  # @return [Integer, nil]
  def version_number(type, path)
    name = version_name(type, path)
    return name.to_i if VERSION_NAME.match?(name)
    return unless @wip

    wip = WIP_NAME.match(name)
    return unless wip

    wip[1].to_i
  end

  def check_duplicate(subject, version, earlier, path)
    return unless earlier

    names = [earlier, path].map { it.basename.to_s }.sort.join(' and ')
    raise DuplicateVersion,
          "#{subject} version #{version} has both #{names} in #{root}"
  end

  def wip_name?(type, path)
    WIP_NAME.match?(version_name(type, path))
  end

  def version_name(type, path)
    path.basename(TYPE_EXTENSIONS[type]).to_s
  end

  def subject_folder(subject)
    root.join(subject)
  end
end
