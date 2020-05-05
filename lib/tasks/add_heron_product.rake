namespace :product_heron do
  desc 'Modifying product criteria'
  task add: [:environment] do
    puts 'Creating new product & product criteria for Heron study...'

    ActiveRecord::Base.transaction do
      PRODUCT_NAME = 'Heron'
      ADDITIONAL_CRITERIA = {
        sanger_sample_id: {},
        sample_description: {},
        phenotype: {},
        plate_barcode: {},
        well_location: {},
        supplier_name: {}
      }.freeze

      product = Product.create!(name: PRODUCT_NAME)

      product_criteria = ProductCriteria.create!(
        product: product,
        stage: 'stock',
        configuration: ADDITIONAL_CRITERIA
      )
    end
  end
end
