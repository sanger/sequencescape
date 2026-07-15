# frozen_string_literal: true

module SequencescapeExcel
  ##
  # Configuration class for sample manifests handling fornatting, manifest types,
  # ranges and columns.
  class Configuration
    include Helpers

    FILES = %i[conditional_formattings ranges columns].freeze

    attr_accessor :folder, :tag_group, :column_sets
    attr_reader :loaded, :files, *FILES

    def initialize
      @files = self.class::FILES.dup
      yield self if block_given?
    end

    def add_file(file)
      @files << file.to_sym
      class_eval { attr_accessor file.to_sym }
    end

    def load!
      return if folder.blank?

      @files.each { |file| send("#{file}=", load_file(folder, file.to_s)) }
      @loaded = true
    end

    def conditional_formattings=(conditional_formattings)
      @conditional_formattings = ConditionalFormattingDefaultList.new(conditional_formattings).freeze
    end

    def columns=(columns)
      @columns = Columns.new(columns, conditional_formattings, column_sets).freeze
    end

    def ranges=(ranges)
      @ranges = RangeList.new(ranges).freeze
    end

    def loaded?
      loaded
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      folder == other.folder && conditional_formattings == other.conditional_formattings && ranges == other.ranges &&
        columns == other.columns
    end

    ##
    # Columns
    class Columns
      attr_reader :all

      def initialize(columns, conditional_formattings, initial_column_sets)
        @all = ColumnList.new(columns, conditional_formattings).freeze

        initial_column_sets.each do |key, manifest_type|
          extract = all.extract(manifest_type.columns).freeze
          instance_variable_set "@#{key}", extract
          class_eval { attr_reader key }
          column_sets[key] = extract
        end
      end

      def find(key)
        column_sets[key] || column_sets[key.to_s]
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        all == other.all
      end

      delegate :count, to: :all

      private

      def column_sets
        @column_sets ||= {}
      end
    end
  end
end
