
class AgressoProduct < ActiveRecord::Base
  establish_connection :agresso_test_db

  self.table_name = 'AGR55.UVIOPSPRODMAPPING'

  def self.product_code(product_name)
    product = find_by(fin_prod_name: product_name)
    product.present? ? product.fin_prod : 'LM9999'
  end
end
