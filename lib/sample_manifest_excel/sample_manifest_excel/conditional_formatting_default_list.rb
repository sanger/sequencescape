module SampleManifestExcel
  class ConditionalFormattingDefaultList

    include Enumerable
    include Comparable

    attr_reader :defaults

    def initialize(defaults)
      create_defaults(defaults)
    end

    def defaults
      @defaults ||= {}
    end

    def find_by(key)
      defaults[key] || defaults[key.to_s]
    end

    def each(&block)
      defaults.each(&block)
    end

    def <=>(other)
      return unless other.is_a?(self.class)
      defaults <=> other.defaults
    end

  private

    def create_defaults(defaults)
      self.defaults.tap do |_defaults|
        defaults.each do |k, default|
          _defaults[k] = ConditionalFormattingDefault.new(default.merge(type: k))
        end
      end
    end

  end
end