module RecordLoader
  class PlatePurposeLoader
    DEFAULT_DIRECTORY = Rails.root.join('config', 'default_records', 'plate_purposes')
    EXTENTION = '.yml'
    DEFAULT_PRINTER_TYPE = '96 Well Plate'
    #
    # Create a new purpose loader from yaml files
    #
    # @param [Array,NilClass] files: pass in an array of files to load, or nil to load all files.
    # @param [Pathname, String] directory: DEFAULT_DIRECTORY The directory from which to load the files.
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

    def existing_purposes
      @existing_purposes ||= Purpose.where(name: @config.keys).pluck(:name)
    end

    def is_yaml?(filename)
      filename.extname == EXTENTION
    end

    def in_list?(list, file)
      (list.nil? || list.include?(file.basename.to_s.gsub(EXTENTION, '')))
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
        plate_purpose: purpose,
        plate_purposes: [purpose],
        parent_plate_purposes: parents
      )
    end

    def barcode_printer_type(name)
      @printer_cache ||= Hash.new { |hash, name| hash[name] = BarcodePrinterType.find_by(name: name) }
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
