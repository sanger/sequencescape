
class AgressoProduct < ActiveRecord::Base
  establish_connection :agresso_test_db

  self.table_name = 'AGRESSOTABLE'

  def self.billing_product_code(billing_product_name)
    product = find_by(fin_prod_name: billing_product_name)
    product.present? ? product.fin_prod : 'LM9999'
  end
end
