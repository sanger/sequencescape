# frozen_string_literal: true

FactoryBot.define do
  # Needs the component tag group: it decides the number of rows per tube.
  # components_per_tube lists the number of filled rows in each tube; by
  # default all the rows of every tube are filled.
  factory :test_download_compound_tubes,
          class: 'SampleManifestExcel::TestDownload' do
    columns { FactoryBot.build(:column_list) }
    validation_errors { [] }
    study { 'WTCCC' }
    supplier { 'Test Supplier' }
    count { 2 }
    type { 'Tubes' }
    manifest_type { 'kinnex_compound_sample_tube' }
    components_per_tube { nil }
    data do
      {
        supplier_name: 'SCG--1222_A0',
        retention_instruction: 'Long term storage',
        library_type: 'My personal library type',
        donor_id: 'id',
        date_of_sample_collection: 'Nov-16',
        country_of_origin: 'United Kingdom',
        gender: 'Unknown',
        phenotype: 'Unknown',
        sample_common_name: 'Homo sapiens',
        sample_public_name: 'SCG--1222_A0',
        sample_taxon_id: 9606
      }.with_indifferent_access
    end

    initialize_with do
      new(
        data:,
        columns:,
        validation_errors:,
        study:,
        supplier:,
        count:,
        type:,
        manifest_type:,
        components_per_tube:
      )
    end

    skip_create
  end
end
