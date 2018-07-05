# frozen_string_literal: true

module SampleManifestExcel
  ##
  # Default list of conditional formattings for a single entity e.g. Column.
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
