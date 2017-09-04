# We'll try and do this through the API with the live version

namespace :billing do
  desc 'Create billing catalogues and products'
  task create_products: [:environment] do

    product_catalogues_attributes = [
      {
        name: :standard_wgs,
        products_attributes: [
          { name: 'Standard WGS' }
        ]
      },
      {
        name: :isc_pulldown,
        differentiator: :bait_library_short_name,
        products_attributes: [
          { name: 'ISC Standard pulldown', differentiator_value: 'standard' },
          { name: 'ISC Custom pulldown', differentiator_value: 'custom' }
        ]
      },
      {
        name: :pcr_free_wgs,
        products_attributes: [
          { name: 'PCR-Free WGS' }
        ]
      },
      {
        name: :lcmb_wgs,
        products_attributes: [
          { name: 'LCMB - WGS' }
        ]
      },
      {
        name: :lcmb_isc_pulldown,
        differentiator: :bait_library_short_name,
        products_attributes: [
          { name: 'LCMB - ISC Standard pulldown', differentiator_value: 'standard' },
          { name: 'LCMB - ISC Custom pulldown', differentiator_value: 'custom' }
        ]
      },
      { name: :miseq_paired_end,
        differentiator: :read_length,
        products_attributes: [
          { name: 'Illumina MiSeq Paired End read length 25 (50 cycle)', differentiator_value: 25 },
          { name: 'Illumina MiSeq Paired End read length 75 (150 cycle)', differentiator_value: 75 },
          { name: 'Illumina MiSeq Paired End read length 150 (300 cycle)', differentiator_value: 150 },
          { name: 'Illumina MiSeq Paired End read length 250 (500 cycle)', differentiator_value: 250 },
          { name: 'Illumina MiSeq Paired End read length 300 (600 cycle)', differentiator_value: 300 }
        ]
      },
      {
        name: :hiseq_2500_paired_end,
        differentiator: :read_length,
        products_attributes: [
          { name: 'Illumina HiSeq 2500 Rapid Runs Paired End read length 250 run', differentiator_value: 250 },
          { name: 'Illumina HiSeq 2500 Rapid Runs Paired End read length 75 run', differentiator_value: 75 },
          { name: 'Illumina HiSeq 2500 Rapid Runs Paired End read length 100 run', differentiator_value: 100 }
        ]
      },
      {
        name: :hiseq_2500_single_end,
        products_attributes: [
          { name: 'Illumina HiSeq 2500 Rapid Runs SINGLE End read length 50SE run' }
        ]
      },
      {
        name: :hiseq_v4_paired_end,
        differentiator: :read_length,
        products_attributes: [
          { name: 'Illumina HiSeq V4 Paired End read length 75', differentiator_value: 75},
          { name: 'Illumina HiSeq V4 Paired End read length 125', differentiator_value: 125}
        ]
      },
      {
        name: :hiseq_v4_single_end,
        differentiator: :read_length,
        products_attributes: [
          { name: 'Illumina HiSeq V4 SINGLE End read length 19 SE', differentiator_value: 19},
          { name: 'Illumina HiSeq V4 SINGLE End read length 50 SE', differentiator_value: 50}
        ]
      },
      {
        name: :hiseq_x_paired_end,
        products_attributes: [
          { name: 'HiSeq X Ten Paired End read length 150' }
        ]
      },
      {
        name: :hiseq_4000_paired_end,
        differentiator: :read_length,
        products_attributes: [
          { name: 'HiSeq 4000 Paired End read length 75', differentiator_value: 75},
          { name: 'HiSeq 4000 Paired End read length 150', differentiator_value: 150},
          { name: 'HiSeq 4000 Paired End read length 25', differentiator_value: 25}]
      }
    ]

    product_catalogues_attributes.each do |product_catalogue_attributes|
      product_catalogue = Billing::ProductCatalogue.find_by(name: product_catalogue_attributes[:name])
      unless product_catalogue.present?
        Billing::ProductCatalogue.create!(product_catalogue_attributes)
        puts "Product catalogue #{product_catalogue_attributes[:name]} was created"
      end
    end
  end

  desc 'Add catalogues to request types'
  task add_to_request_types: %i(environment create_products) do
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
        request_type.update_attributes(billing_product_catalogue: product_catalogue)
        puts "Product catalogue #{product_catalogue_name} added to request type #{request_type_key}"
      end
    end
  end
end