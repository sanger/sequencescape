namespace :product_criteria do
  desc 'Modifying product criteria'
  task add_phenotype: [:environment] do
    puts 'Adding phenotype to product criteria...'
    ActiveRecord::Base.transaction do
      PRODUCTS_LIST = %w[MWGS PWGS HSqX].freeze
      ADDED_CRITERIA = {
        phenotype: {}
      }.freeze

      PRODUCTS_LIST.each do |product_name|
        puts "Checking product #{product_name}"
        product = Product.find_by!(name: product_name)
        product_criteria = product.stock_criteria || next
        puts "Adding phenotype to for product #{product_name}"

        cloned_product_criteria = product_criteria.dup
        product_criteria&.deprecate!
        cloned_product_criteria.configuration.merge!(ADDED_CRITERIA)
        cloned_product_criteria.save!
      end
    end
  end
end
