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

      ProductCriteria.create!(
        product: product,
        stage: 'stock',
        configuration: ADDITIONAL_CRITERIA
      )
    end
  end
end
