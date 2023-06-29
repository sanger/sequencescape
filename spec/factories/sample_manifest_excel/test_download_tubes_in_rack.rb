# frozen_string_literal: true

FactoryBot.define do
  factory :test_download_tubes_in_rack, class: 'SampleManifestExcel::TestDownload' do
    columns { FactoryBot.build(:column_list) }
    validation_errors { [] }
    no_of_rows { 3 } # TODO: this seems to actually be 'number of rows in addition to first row'...?
    study { 'WTCCC' }
    supplier { 'Test Supplier' }
    count { 2 }
    partial { false }
    cgap { false }
    type { 'Tube Racks' }
    manifest_type { 'tube_rack_default' }
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
        data: data,
        columns: columns,
        validation_errors: validation_errors,
        no_of_rows: no_of_rows,
        partial: partial,
        cgap: cgap,
        study: study,
        supplier: supplier,
        count: count,
        type: type,
        manifest_type: manifest_type
      )
    end

    skip_create
  end
end
