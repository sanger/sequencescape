module Billing
  # fields details are stored in config/billing/fields.yml file
  class FieldsList
    include Enumerable

    attr_accessor :fields

    def initialize(fields_details = {})
      @fields = create_fields(fields_details)
    end

    def each(&block)
      fields.each(&block)
    end

    def spaces_to_next_field(field)
      next_field = next_field(field)
      next_field.position_from - field.position_to - 1 if next_field.present?
    end

    def next_field(field)
      find { |next_field| next_field.order == field.order + 1 }
    end

    def create_fields(fields = {})
      [].tap do |fields_list|
        fields.each do |key, value|
          fields_list << Field.new(value.merge(name: key))
        end
      end
    end
  end
end
