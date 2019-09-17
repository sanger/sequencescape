namespace :billing do
  desc 'Create billing catalogues and products'
  task create_products: [:environment] do
    product_catalogues_attributes = [
      {
        name: :standard_wgs,
        billing_products_attributes: [
          { name: 'Standard WGS', category: 'library_creation' }
        ]
      },
      {
        name: :isc_pulldown,
        billing_products_attributes: [
          { name: 'ISC Standard pulldown', identifier: 'standard', category: 'library_creation' },
          { name: 'ISC Custom pulldown', identifier: 'custom', category: 'library_creation' }
        ]
      },
      {
        name: :pcr_free_wgs,
        billing_products_attributes: [
          { name: 'PCR-Free WGS', category: 'library_creation' }
        ]
      },
      {
        name: :lcmb_wgs,
        billing_products_attributes: [
          { name: 'LCMB - WGS', category: 'library_creation' }
        ]
      },
      {
        name: :lcmb_isc_pulldown,
        billing_products_attributes: [
          { name: 'LCMB - ISC Standard pulldown', identifier: 'standard', category: 'library_creation' },
          { name: 'LCMB - ISC Custom pulldown', identifier: 'custom', category: 'library_creation' }
        ]
      },
      { name: :miseq_paired_end,
        billing_products_attributes: [
          { name: 'Illumina MiSeq Paired End read length 25 (50 cycle)', identifier: 25, category: 'sequencing' },
          { name: 'Illumina MiSeq Paired End read length 75 (150 cycle)', identifier: 75, category: 'sequencing' },
          { name: 'Illumina MiSeq Paired End read length 150 (300 cycle)', identifier: 150, category: 'sequencing' },
          { name: 'Illumina MiSeq Paired End read length 250 (500 cycle)', identifier: 250, category: 'sequencing' },
          { name: 'Illumina MiSeq Paired End read length 300 (600 cycle)', identifier: 300, category: 'sequencing' }
        ] },
      {
        name: :hiseq_2500_paired_end,
        billing_products_attributes: [
          { name: 'Illumina HiSeq 2500 Rapid Runs Paired End read length 250 run', identifier: 250, category: 'sequencing' },
          { name: 'Illumina HiSeq 2500 Rapid Runs Paired End read length 75 run', identifier: 75, category: 'sequencing' },
          { name: 'Illumina HiSeq 2500 Rapid Runs Paired End read length 100 run', identifier: 100, category: 'sequencing' }
        ]
      },
      {
        name: :hiseq_2500_single_end,
        billing_products_attributes: [
          { name: 'Illumina HiSeq 2500 Rapid Runs SINGLE End read length 50SE run', category: 'sequencing' }
        ]
      },
      {
        name: :hiseq_v4_paired_end,
        billing_products_attributes: [
          { name: 'Illumina HiSeq V4 Paired End read length 75', identifier: 75, category: 'sequencing' },
          { name: 'Illumina HiSeq V4 Paired End read length 125', identifier: 125, category: 'sequencing' }
        ]
      },
      {
        name: :hiseq_v4_single_end,
        billing_products_attributes: [
          { name: 'Illumina HiSeq V4 SINGLE End read length 19 SE', identifier: 19, category: 'sequencing' },
          { name: 'Illumina HiSeq V4 SINGLE End read length 50 SE', identifier: 50, category: 'sequencing' }
        ]
      },
      {
        name: :hiseq_x_paired_end,
        billing_products_attributes: [
          { name: 'HiSeq X Ten Paired End read length 150', category: 'sequencing' }
        ]
      },
      {
        name: :hiseq_4000_paired_end,
        billing_products_attributes: [
          { name: 'HiSeq 4000 Paired End read length 75', identifier: 75, category: 'sequencing' },
          { name: 'HiSeq 4000 Paired End read length 150', identifier: 150, category: 'sequencing' },
          { name: 'HiSeq 4000 Paired End read length 25', identifier: 25, category: 'sequencing' }
        ]
      }
    ]

    product_catalogues_attributes.each do |product_catalogue_attributes|
      product_catalogue = Billing::ProductCatalogue.find_by(name: product_catalogue_attributes[:name])
      if product_catalogue.blank?
        Billing::ProductCatalogue.create!(product_catalogue_attributes)
        puts "Product catalogue #{product_catalogue_attributes[:name]} was created"
      end
    end
  end

  desc 'Add catalogues to request types'
  task add_billing_product_catalogues_to_request_types: %i(environment create_products) do
    request_types_to_product_catalogues_map = {
      limber_wgs: :standard_wgs,
      limber_isc: :isc_pulldown,
      limber_pcr_free: :pcr_free_wgs,
      limber_lcmb: :lcmb_wgs,
      limber_reisc: :lcmb_isc_pulldown,
      illumina_c_miseq_sequencing: :miseq_paired_end,
      illumina_b_miseq_sequencing: :miseq_paired_end,
      illumina_c_hiseq_2500_paired_end_sequencing: :hiseq_2500_paired_end,
      illumina_b_hiseq_2500_paired_end_sequencing: :hiseq_2500_paired_end,
      illumina_b_hiseq_2500_single_end_sequencing: :hiseq_2500_single_end,
      illumina_c_hiseq_2500_single_end_sequencing: :hiseq_2500_single_end,
      illumina_b_hiseq_v4_paired_end_sequencing: :hiseq_v4_paired_end,
      illumina_c_hiseq_v4_paired_end_sequencing: :hiseq_v4_paired_end,
      illumina_c_hiseq_v4_single_end_sequencing: :hiseq_v4_single_end,
      illumina_b_hiseq_x_paired_end_sequencing: :hiseq_x_paired_end,
      bespoke_hiseq_x_paired_end_sequencing: :hiseq_x_paired_end,
      illumina_htp_hiseq_4000_paired_end_sequencing: :hiseq_4000_paired_end,
      illumina_c_hiseq_4000_paired_end_sequencing: :hiseq_4000_paired_end
    }

    request_types_to_product_catalogues_map.each do |request_type_key, product_catalogue_name|
      request_type = RequestType.find_by(key: request_type_key)
      product_catalogue = Billing::ProductCatalogue.find_by(name: product_catalogue_name)
      if request_type.present? && product_catalogue.present?
        request_type.update(billing_product_catalogue: product_catalogue)
        puts "Product catalogue #{product_catalogue_name} was added to request type #{request_type_key}"
      end
    end
  end

  desc 'Billing setup'
  task setup: %i(environment create_products add_billing_product_catalogues_to_request_types) do
  end
end
