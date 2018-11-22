# frozen_string_literal: true

module SequencescapeExcel
  ##
  # An Excel validation
  # Holds the validation for each column which is added to each column when the spreadsheet is created.
  # Consists of:
  # - A list of options which relate to options recognised by Excel e.g. errorMessage.
  # - A range name (optional) which will be linked to a range when the spreadsheet is created.
  class Validation
    include Helpers::Attributes

    setup_attributes :options, :range_name

    def initialize(attributes = {})
      super
    end

    ##
    # The range is updated when the measurements of a worksheet is defined.
    # If a range is required the the formula1 is set to the absolute raference
    # of the range.
    # If a worksheet is passed then the data validation is added using the reference is passed
    # and the options for the validation.
    def update(attributes = {})
      options[:formula1] = attributes[:range].absolute_reference if range_required?
      return if attributes[:worksheet].blank?

      @worksheet_validation = attributes[:worksheet].add_data_validation(attributes[:reference], options)
    end

    ##
    # If the range name is present then a range is required for the validation
    def range_required?
      range_name.present?
    end

    ##
    # formula1 is defined within the options
    def formula1
      options[:formula1]
    end

    ##
    # Validation is only valid if there are some options
    def valid?
      options.present?
    end

    ##
    # A validation object is never empty
    def empty?
      false
    end

    ##
    # If the worksheet has been updated then we can assume that the validation
    # has been saved to a worksheet.
    def saved?
      @worksheet_validation.present?
    end

    def initialize_dup(source)
      self.options = source.options.dup
      super
    end

    def inspect
      "<#{self.class}: @options=#{options}, @range_name=#{range_name}>"
    end
  end
end
