module SampleManifestExcel

  class ConditionalFormattingList

    include Enumerable

    attr_reader :conditional_formattings

    delegate :empty?, to: :conditional_formattings

    def initialize(conditional_formattings = {})
      create_conditional_formattings(conditional_formattings)
      yield self if block_given?
    end

    def conditional_formattings
      @conditional_formattings ||= {}
    end

    def each(&block)
      conditional_formattings.each(&block)
    end

    def each_item(&block)
      conditional_formattings.values.each(&block)
    end

    def update(attributes = {})
      each do |k, conditional_formatting|
        conditional_formatting.update(attributes)
      end

      if attributes[:worksheet].present?
        @saved = attributes[:worksheet].add_conditional_formatting(attributes[:reference], options)
      end

      self
    end

    def options
      conditional_formattings.values.collect(&:options)
    end

    def create_conditional_formattings(conditional_formattings)
      self.conditional_formattings.tap do |cf|
        conditional_formattings.each do |key, conditional_formatting|
          cf[key] = ConditionalFormatting.new(conditional_formatting)
        end
      end
    end

    def saved?
      @saved.present?
    end
  end
end