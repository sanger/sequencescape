# Simple record that stores (dynamic) data required to generate billing BIF file
# it store request_id, project_cost_code, units, fin_product_code, fin_product_description, request_passed_date
module Billing
  class Item < ActiveRecord::Base
    belongs_to :request
  end
end
