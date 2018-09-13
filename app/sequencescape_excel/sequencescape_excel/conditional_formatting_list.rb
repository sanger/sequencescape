# frozen_string_literal: true

module SequencescapeExcel
  ##
  # A list of conditional formattings for a single entity e.g. Column.
  class ConditionalFormattingList
    include List

    list_for :conditional_formattings, keys: [:name]

    delegate :empty?, to: :conditional_formattings

    def initialize(conditional_formattings = {})
      create_conditional_formattings(conditional_formattings)
      yield self if block_given?
    end

    ##
    # Forwarding method. Calls update on each conditional formatting.
    # If the attributes contain a worksheet will add all of the
    # options for the list to a reference in the worksheet.
    def update(attributes = {})
      each do |conditional_formatting|
        conditional_formatting.update(attributes)
      end

      @saved = attributes[:worksheet].add_conditional_formatting(attributes[:reference], options) if attributes[:worksheet].present? && conditional_formattings.any?

      self
    end

    ##
    # Collect all of the options for each item in the list.
    def options
      collect(&:options)
    end

    ##
    # create a new conditional formatting for each item in the passed hash
    # for each key.
    def create_conditional_formattings(conditional_formattings)
      conditional_formattings.each do |key, conditional_formatting|
        add(if conditional_formatting.is_a?(Hash)
              ConditionalFormatting.new(conditional_formatting.merge(name: key))
            else
              key.dup
            end)
      end
    end

    ##
    # A list has been saved if the options have been passed to a worksheet.
    def saved?
      @saved.present?
    end

    ##
    # The conditional formattings instance variable needs to be reset to an empty hash
    # otherwise the hash is still copied and will not duplicate correctly.
    def initialize_dup(source)
      reset!
      create_conditional_formattings(source.conditional_formattings)
      super
    end
  end
end
