# frozen_string_literal: true

FactoryBot.define do
  factory :test_download_tubes, class: 'SampleManifestExcel::TestDownload' do
    columns { FactoryBot.build(:column_list) }
    validation_errors { [] }
    no_of_rows { 5 }
    study { 'WTCCC' }
    supplier { 'Test Supplier' }
    count { 1 }
    partial { false }
    cgap { false }
    type { 'Tubes' }
    manifest_type { 'tube_full' }
    data do
      {
        country_of_origin: 'United Kingdom',
        library_type: 'My personal library type',
        reference_genome: 'My reference genome',
        insert_size_from: 200,
        insert_size_to: 1500,
        supplier_name: 'SCG--1222_A0',
        volume: 1,
        concentration: 1,
        gender: 'Unknown',
        dna_source: 'Cell Line',
        date_of_sample_collection: 'Nov-16',
        date_of_sample_extraction: 'Nov-16',
        sample_purified: 'No',
        sample_public_name: 'SCG--1222_A0',
        sample_taxon_id: 9606,
        sample_common_name: 'Homo sapiens',
        donor_id: 'id',
        phenotype: 'Unknown'
      }.with_indifferent_access
    end

    initialize_with do
      new(
        data:,
        columns:,
        validation_errors:,
        no_of_rows:,
        partial:,
        cgap:,
        study:,
        supplier:,
        count:,
        type:,
        manifest_type:
      )
    end

    skip_create

    # in partial download, 4 rows out of 6 are populated
    # 2 empty rows do not have supplier_sample_name and tags
    factory :test_download_tubes_partial, class: 'SampleManifestExcel::TestDownload' do
      partial { true }
    end

    # in cgap download, the sanger_tube_id column values are cgap barcodes
    factory :test_download_tubes_cgap, class: 'SampleManifestExcel::TestDownload' do
      cgap { true }
    end
  end
end
