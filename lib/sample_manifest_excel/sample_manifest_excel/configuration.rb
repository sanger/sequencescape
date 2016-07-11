module SampleManifestExcel
  
  class Configuration

    include SampleManifestExcel::Helpers

    FILES = [:conditional_formattings, :manifest_types, :ranges, :columns]

    attr_accessor :folder, *FILES
    attr_reader :loaded, :files

    def initialize
      @files = FILES.dup
      yield self if block_given?
    end

    def add_file(file)
      @files << file.to_sym
      self.class_eval { attr_accessor file.to_sym }
    end

    def load!
      if folder.present?
        FILES.each do |file|
          self.send("#{file}=", load_file(folder, file.to_s))
        end
        @loaded = true
      end
    end

    def conditional_formattings=(conditional_formattings)
      @conditional_formattings = ConditionalFormattingDefaultList.new(conditional_formattings).freeze
    end

    def columns=(columns)
      @columns = Columns.new(columns, conditional_formattings, manifest_types).freeze
    end

    def ranges=(ranges)
      @ranges = RangeList.new(ranges).freeze
    end

    def manifest_types=(manifest_types)
      @manifest_types = manifest_types.with_indifferent_access.freeze
    end

    def loaded?
      loaded
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      folder == other.folder &&
      conditional_formattings == other.conditional_formattings &&
      manifest_types == other.manifest_types &&
      ranges == other.ranges &&
      columns == other.columns
    end

    class Columns

      attr_reader :all

      def initialize(columns, conditional_formattings, manifest_types)
        @all = ColumnList.new(columns, conditional_formattings).freeze

        manifest_types.each do |key, column_names|
          instance_variable_set "@#{key}", all.extract(column_names).freeze
          self.class_eval { attr_reader key }
        end
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        all == other.all
      end
    end

  end
end