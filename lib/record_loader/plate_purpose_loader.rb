module RecordLoader
  class PlatePurposeLoader
    # The directory from which to load yml files.
    DEFAULT_DIRECTORY = Rails.root.join('config', 'default_records', 'plate_purposes')
    # The file type to load
    EXTENSION = '.yml'
    # The name of the default printer type
    DEFAULT_PRINTER_TYPE = '96 Well Plate'
    #
    # Create a new purpose loader from yaml files
    #
    # @param files [Array,NilClass] pass in an array of files to load, or nil to load all files.
    # @param directory [Pathname, String] The directory from which to load the files.
    #   defaults to config/default_records/plate_purposes
    #
    def initialize(files: nil, directory: DEFAULT_DIRECTORY)
      path = directory.is_a?(Pathname) ? directory : Pathname.new(directory)
      @files = path.children.select do |child|
        is_yaml?(child) && in_list?(files, child)
      end
      load_config
    end

    def create!
      ActiveRecord::Base.transaction do
        @config.each do |name, config|
          next if existing_purposes.include?(name)

          create_purpose(name, config)
        end
      end
    end

    private

    #
    # Returns the purposes from the list that have already been created
    #
    #
    # @return [Array<String>] An array of names of purposes in the config which already exist
    #
    def existing_purposes
      @existing_purposes ||= Purpose.where(name: @config.keys).pluck(:name)
    end

    #
    # Returns true if filename is a yaml file
    #
    # @param [Pathname] filename The file to be checked
    #
    # @return [Bool] returns true if the file is a yaml file, false otherwise
    #
    def is_yaml?(filename)
      filename.extname == EXTENSION
    end

    def in_list?(list, file)
      (list.nil? || list.include?(file.basename.to_s.gsub(EXTENSION, '')))
    end

    def create_purpose(name, config)
      creator = config.delete('plate_creator')
      config['barcode_printer_type'] = barcode_printer_type(config.delete('barcode_printer_type'))
      config['name'] = name
      purpose = PlatePurpose.create!(config)
      build_creator(purpose, creator) if creator
    end

    def build_creator(purpose, creator_options)
      config = creator_options.respond_to?(:[]) ? creator_options : {}
      parents = Purpose.where(name: config.fetch('from', []))
      Plate::Creator.create!(
        name: purpose.name,
        plate_purposes: [purpose],
        parent_plate_purposes: parents
      )
    end

    def barcode_printer_type(name)
      @printer_cache ||= Hash.new do |hash, uncached_type_name|
        hash[uncached_type_name] = BarcodePrinterType.find_by(name: uncached_type_name)
      end
      @printer_cache[name || DEFAULT_PRINTER_TYPE]
    end

    #
    # Load the appropriate configuration files into @config
    #
    def load_config
      @config = @files.each_with_object({}) do |file, store|
        latest_file = YAML.parse_file(file).to_ruby
        store.merge!(latest_file)
      end
    end
  end
end
