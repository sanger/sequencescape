class ChangeCriteriaIhtp < ActiveRecord::Migration
  PRODUCTS_LIST = %w(MWGS PWGS ISC HSqX)
  ADDED_CRITERIA = {
    concentration: { less_than: 1 },
    concentration_from_normalization: { less_than: 1 },
    rin: { less_than: 6 },
    gender_markers: {}
  }

  def up
    PRODUCTS_LIST.each do |product_name|
      product = Product.find_by!(name: product_name)
      product_criteria = product.stock_criteria || next

      cloned_product_criteria = product_criteria.dup
      product_criteria.deprecate! if product_criteria
      cloned_product_criteria.configuration.merge!(ADDED_CRITERIA)
      cloned_product_criteria.save!
    end
  end

  def down
  end
end
