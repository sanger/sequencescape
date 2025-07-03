# frozen_string_literal: true

module SequencescapeExcel
  ##
  # Column creates a particular column with all the information about this column (name, heading,
  # value, type, attribute, should it be locked or unlocked, position of the column,
  # validation, conditional formatting rules)
  # A column is only valid if it has a name and heading.
  class Column
    include Helpers::Attributes

    setup_attributes :name,
                     :updates,
                     :heading,
                     :number,
                     :type,
                     :validation,
                     :value,
                     :unlocked,
                     :conditional_formattings,
                     :attribute,
                     :range,
                     defaults: {
                       number: 0,
                       type: :string,
                       conditional_formattings: Hash.new, # rubocop:disable Style/EmptyLiteral
                       validation: NullValidation.new
                     }

    validates_presence_of :name, :heading

    delegate :range_name, to: :validation

    # TODO: Because of the way Sample::Metadata is autoloaded we can't check instance_methods.
    # creating a new instance of Sample::Metadata even at startup is incredibly slow.
    # Can't do it as a constant due to Travis failure.
    def self.sample_metadata_model
      @sample_metadata_model ||= Sample::Metadata.new
    end

    def initialize(attributes = {})
      super(default_attributes.merge(attributes))
      self.updates ||= name
    end

    ##
    # If argument is a validation object copy it otherwise
    # create a new validation object
    def validation=(validation)
      return if validation.nil?

      @validation = validation.is_a?(Hash) ? Validation.new(validation) : validation.dup
    end

    ##
    # If argument is a conditional formatting list copy it
    # otherwise create a new conditional formatting list
    def conditional_formattings=(conditional_formattings)
      return if conditional_formattings.nil?

      @conditional_formattings =
        if conditional_formattings.is_a?(Hash)
          ConditionalFormattingList.new(conditional_formattings)
        else
          conditional_formattings.dup
        end
    end

    ##
    # Creates a new Range object.
    def range=(attributes)
      return if attributes.nil?

      @range = attributes.empty? ? NullRange.new : Range.new(attributes)
    end

    ##
    # Some columns need to be unlocked so data can be entered.
    def unlocked?
      unlocked
    end

    def style
      [unlocked? ? :unlocked : :locked, type]
    end

    def metadata_field?
      @metadata_field ||= Column.sample_metadata_model.respond_to?(updates) unless specialised_field?
    end

    def update_metadata(metadata, value)
      metadata.send("#{updates}=", value) if metadata_field?
    end

    def attribute_value(detail)
      detail[attribute] || value
    end

    def specialised_field?
      # We can't use const_defined? here as we want to make sure we trigger rails class loading
      specialised_field.present?
    end

    def specialised_field
      @specialised_field ||= SequencescapeExcel::SpecialisedField.const_get(classify_name, false)
    rescue NameError
      nil
    end

    ##
    # Check whether a column has been updated with all of the references, validations etc.
    def updated?
      @updated
    end

    ##
    # Create a column range based on the first column, first row and last low
    # If the column has a validation range return it or return a NullRange.
    # Update the column validation using the passed worksheet and found range.
    # Update the conditional formatting based on a range and worksheet.
    def update(first_row, last_row, ranges, worksheet)
      self.range = { first_column: number, first_row: first_row, last_row: last_row }

      range = ranges.find_by(range_name) || NullRange.new
      validation.update(range: range, reference: self.range.reference, worksheet: worksheet)

      conditional_formattings.update(
        self.range.references.merge(absolute_reference: range.absolute_reference, worksheet: worksheet)
      )

      @updated = true

      self
    end

    def initialize_dup(source)
      self.range = {}
      self.validation = source.validation
      self.conditional_formattings = source.conditional_formattings
      super
    end

    def self.build_arguments(args, key, conditional_formattings)
      ArgumentBuilder.new(args, key, conditional_formattings).to_h
    end

    # Builds arguments
    class ArgumentBuilder
      attr_reader :arguments

      def initialize(args, key, default_conditional_formattings)
        @arguments = args.merge(name: key)
        combine_conditional_formattings(default_conditional_formattings)
      end

      def to_h
        arguments
      end

      def inspect
        "<#{self.class}: @name=#{name}, @updates=#{updates}, @heading=#{heading}, @number=#{number}, @type=#{type}, " \
          "@validation#{validation}, @value=#{value}, @unlocked=#{unlocked}, " \
          "@conditional_formattings=#{conditional_formattings}, @attribute=#{attribute}, @range=#{range}>"
      end

      private

      def combine_conditional_formattings(defaults)
        return if arguments[:conditional_formattings].blank?

        arguments[:conditional_formattings].each do |k, cf|
          arguments[:conditional_formattings][k] = defaults.find_by(:type, k).combine(cf)
        end
      end
    end

    private

    attr_reader :attribute

    def classify_name
      updates.to_s.delete('?').classify
    end
  end
end
