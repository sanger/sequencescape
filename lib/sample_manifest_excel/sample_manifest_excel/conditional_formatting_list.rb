module SampleManifestExcel
  ##
  # A list of conditional formattings for a single entity e.g. Column.
  class ConditionalFormattingList
    include Enumerable
    include Comparable

    attr_reader :conditional_formattings

    delegate :empty?, to: :conditional_formattings

    def initialize(conditional_formattings = {})
      create_conditional_formattings(conditional_formattings)
      yield self if block_given?
    end

    ##
    # Defaults to an empty hash
    def conditional_formattings
      @conditional_formattings ||= {}
    end

    def each(&block)
      conditional_formattings.each(&block)
    end

    ##
    # Extracts each item
    def each_item(&block)
      conditional_formattings.values.each(&block)
    end

    ##
    # Forwarding method. Calls update on each conditional formatting.
    # If the attributes contain a worksheet will add all of the
    # options for the list to a reference in the worksheet.
    def update(attributes = {})
      each do |_k, conditional_formatting|
        conditional_formatting.update(attributes)
      end

      if attributes[:worksheet].present? && conditional_formattings.any?
        @saved = attributes[:worksheet].add_conditional_formatting(attributes[:reference], options)
      end

      self
    end

    ##
    # Collect all of the options for each item in the list.
    def options
      conditional_formattings.values.collect(&:options)
    end

    ##
    # create a new conditional formatting for each item in the passed hash
    # for each key.
    def create_conditional_formattings(conditional_formattings)
      self.conditional_formattings.tap do |cf|
        conditional_formattings.each do |key, conditional_formatting|
          cf[key] = if conditional_formatting.kind_of?(Hash)
                      ConditionalFormatting.new(conditional_formatting)
                    else
                      conditional_formatting.dup
                    end
        end
      end
    end

    ##
    # A list has been saved if the options have been passed to a worksheet.
    def saved?
      @saved.present?
    end

    def <=>(other)
      return unless other.is_a?(self.class)
      conditional_formattings <=> other.conditional_formattings
    end

    ##
    # The conditional formattings instance variable needs to be reset to an empty hash
    # otherwise the hash is still copied and will not duplicate correctly.
    # TODO: extract the behaviour out of all the lists and make it more generic.
    def initialize_dup(source)
      reset!
      create_conditional_formattings(source.conditional_formattings)
      super
    end

  private

    def reset!
      @conditional_formattings = {}
    end
  end
end
