# frozen_string_literal: true
namespace :product_heron do
  desc 'Modifying product criteria'
  task add: [:environment] do
    puts 'Creating new product & product criteria for Heron study...'

    ActiveRecord::Base.transaction do
      ADDITIONAL_CRITERIA = {
        sanger_sample_id: {},
        sample_description: {},
        phenotype: {},
        plate_barcode: {},
        well_location: {},
        supplier_name: {}
      }.freeze

      product = Product.create!(name: 'Heron')

      ProductCriteria.create!(product: product, stage: 'stock', configuration: ADDITIONAL_CRITERIA)
    end
  end

  task add_storage_location: [:environment] do
    puts 'Adding storage location...'

    ActiveRecord::Base.transaction do
      ADDITIONAL_CRITERIA = { storage_location: {} }.freeze

      product = Product.find_by!(name: 'Heron')
      existing_product_criteria = product.stock_criteria
      if existing_product_criteria
        cloned_product_criteria = existing_product_criteria.dup
        existing_product_criteria.deprecate!
        cloned_product_criteria.configuration.merge!(ADDITIONAL_CRITERIA)
        cloned_product_criteria.save!
        puts 'Done'
      else
        puts 'Failed to find existing product criteria, could not update'
      end
    end
  end
end
