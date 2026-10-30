# frozen_string_literal: true

FactoryBot.define do
  # The component tag group decides the number of rows per plate. The factory
  # creates it, with component_tag_count tags, unless it already exists.
  # components_per_tube lists the number of filled rows in each plate; by
  # default all the rows of every plate are filled.
  factory :test_download_compound_plates,
          class: 'SampleManifestExcel::TestDownload' do
    transient { component_tag_count { 4 } }

    columns { FactoryBot.build(:column_list) }
    validation_errors { [] }
    study { 'WTCCC' }
    supplier { 'Test Supplier' }
    count { 2 }
    type { 'Plates' }
    manifest_type { 'kinnex_compound_sample_plate' }
    components_per_tube { nil }
    data do
      {
        supplier_name: 'SCG--1222_A0',
        retention_instruction: 'Long term storage',
        library_type_kinnex: 'Pacbio_Kinnex_Full_Length',
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
      handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
      handler.tag_group || FactoryBot.create(
        :tag_group,
        name: handler::TAG_GROUP_NAME,
        tag_count: component_tag_count
      )
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
