module SampleManifestExcel
  class ConditionalFormattingDefaultList

    include List

    list_for :defaults, keys: [:type]

    def initialize(defaults)
      create_defaults(defaults)
      yield self if block_given?
    end

  private

    def create_defaults(defaults)
      defaults.each do |k, default|
        add ConditionalFormattingDefault.new(default.merge(type: k))
      end
    end
  end
end
