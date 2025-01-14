# frozen_string_literal: true

FactoryBot.define do
  factory :test_download_plates, class: 'SampleManifestExcel::TestDownload' do
    columns { build(:column_list) }
    validation_errors { [] }
    num_plates { 2 }
    num_filled_wells_per_plate { 2 }
    num_rows_per_well { 1 }
    study { 'WTCCC' }
    supplier { 'Test Supplier' }
    partial { false }
    cgap { false }
    type { 'Plates' }
    manifest_type { 'plate_full' }
    data do
      {
        supplier_name: 'SCG--1222_A0',
        volume: 1,
        concentration: 1,
        country_of_origin: 'United Kingdom',
        gender: 'Unknown',
        dna_source: 'Cell Line',
        date_of_sample_collection: 'Nov-16',
        date_of_sample_extraction: 'Nov-16',
        sample_purified: 'No',
        sample_public_name: 'SCG--1222_A0',
        sample_taxon_id: 9606,
        sample_common_name: 'Homo sapiens',
        phenotype: 'Unknown',
        retention_instruction: 'Long term storage',
        huMFre_code: '12/1234'
      }.with_indifferent_access
    end

    initialize_with do
      new(
        data:,
        columns:,
        validation_errors:,
        partial:,
        cgap:,
        study:,
        supplier:,
        num_plates:,
        num_filled_wells_per_plate:,
        num_rows_per_well:,
        type:,
        manifest_type:
      )
    end

    skip_create

    # in partial download, last 2 rows are left empty
    factory :test_download_plates_partial, class: 'SampleManifestExcel::TestDownload' do
      partial { true }
    end

    # in cgap download, the sanger_plate_id column values are cgap barcodes
    factory :test_download_plates_cgap, class: 'SampleManifestExcel::TestDownload' do
      cgap { true }
    end

    factory :test_download_plates_partial_cgap, class: 'SampleManifestExcel::TestDownload' do
      partial { true }
      cgap { true }
    end
  end
end
