module Accession
  class Configuration
    include Accession::Helpers
    include Accession::Equality

    FILES = [:tags]

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
      if folder.present?
        FILES.each do |file|
          send("#{file}=", load_file(folder, file.to_s))
        end
        @loaded = true
      end
    end

    def loaded?
      loaded
    end

    def tags=(tags)
      @tags = TagList.new(tags).freeze
    end

    def attributes
      [:folder, :tags]
    end
  end
end
