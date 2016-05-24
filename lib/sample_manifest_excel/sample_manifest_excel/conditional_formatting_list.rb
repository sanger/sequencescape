module SampleManifestExcel

  class ConditionalFormattingList

    include Enumerable

    attr_reader :conditional_formattings

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

    def create_conditional_formattings(conditional_formattings)
      self.conditional_formattings.tap do |cf|
        conditional_formattings.each do |key, conditional_formatting|
          cf[key] = conditional_formatting
        end
      end
    end
  end
end