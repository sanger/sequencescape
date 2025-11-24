# frozen_string_literal: true
module Accession
  class Configuration
    include Accession::Helpers
    include Accession::Equality

    # This constant defines a list of tags for loading
    # @return [Array<Symbol>] a list of symbols
    FILES = [:tags].freeze

    attr_accessor :folder, *FILES
    attr_reader :loaded, :files

    def initialize
      @files = FILES.dup
      yield self if block_given?
    end

    def add_file(file)
      @files << file.to_sym
      class_eval { attr_accessor file.to_sym }
    end

    def load!
      return unless folder.present?

      FILES.each { |file| send("#{file}=", load_file(folder, file.to_s)) }
      @loaded = true
    end

    def loaded?
      loaded
    end

    def tags=(tags)
      @tags = TagList.new(tags).freeze
    end

    def attributes
      %i[folder tags]
    end
  end
end
