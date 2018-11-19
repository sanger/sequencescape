module Billing
  # Simple record that stores (dynamic) data required to generate billing BIF file
  # it store request_id, project_cost_code, units, billing_product_code, billing_product_description, request_passed_date
  class Item < ActiveRecord::Base
    belongs_to :request

    def self.created_between(start_date, end_date)
      where(created_at: start_date..end_date)
    end

    # this method transfers billing_item to one BIF file entry (string)
    def to_s(fields)
      check_product_code
      ''.tap do |result|
        fields.each do |field|
          result << field.value(self).public_send(field.alignment, field.length)
          result << ' ' * fields.spaces_to_next_field(field).to_i
        end
        result << "\n"
      end
    end

    private

    def check_product_code
      update!(billing_product_code: AgressoProduct.billing_product_code(billing_product_name)) unless billing_product_code.present?
    end
  end
end
