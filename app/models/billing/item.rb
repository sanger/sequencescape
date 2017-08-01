module Billing
  # Simple record that stores (dynamic) data required to generate billing BIF file
  # it store request_id, project_cost_code, units, fin_product_code, fin_product_description, request_passed_date
  class Item < ActiveRecord::Base
    belongs_to :request

    def self.created_between(start_date, end_date)
      where(created_at: start_date..end_date)
    end

    # this method transfers billing_item to one BIF file entry (string)
    def to_s(fields)
      ''.tap do |result|
        fields.each do |field|
          result << format("%#{field.alignment}#{field.length}.#{field.length}s", field.value(self))
          result << format("%-#{fields.spaces_to_next_field(field)}.#{fields.spaces_to_next_field(field)}s", '')
        end
        result << "\n"
      end
    end
  end
end
