# frozen_string_literal: true

# Provides tools for seeding / updating database records
module RecordLoader
  # Inherit from RecordLoader base to automatically load one or more yaml files
  # into a @config hash. Config folders are found in config/default_records
  # and each loader should specify its own subfolder by setting the config_folder
  # class attribute.
  class Base
    BASE_CONFIG_PATH = %w[config default_records].freeze
    EXTENSION = '*.yml'

    class_attribute :config_folder

    #
    # Create a new config loader from yaml files
    #
    # @param files [Array,NilClass] pass in an array of files to load, or nil to load all files.
    # @param directory [Pathname, String] The directory from which to load the files.
    #   defaults to config/default_records/plate_purposes
    #
    def initialize(files: nil, directory: default_path)
      path = directory.is_a?(Pathname) ? directory : Pathname.new(directory)
      @files = path.glob(EXTENSION).select { |child| in_list?(files, child) }
      load_config
    end

    private

    def default_path
      Rails.root.join(*BASE_CONFIG_PATH, config_folder)
    end

    def in_list?(list, file)
      (list.nil? || list.include?(file.basename('.yml').to_s))
    end

    #
    # Load the appropriate configuration files into @config
    #
    def load_config
      @config = @files.each_with_object({}) do |file, store|
        latest_file = YAML.load_file(file)
        store.merge!(latest_file)
      end
    end
  end
end
