# frozen_string_literal: true

FactoryBot.define do
  factory :column, class: 'SequencescapeExcel::Column' do
    sequence(:number) { |n| n }
    name { :"column_#{number}" }
    heading { "Column #{number}" }
    value { "Value #{number}" }

    initialize_with { new(name:, heading:, number:, value:) }

    factory :sanger_sample_id_column do
      name { :sanger_sample_id }
      heading { 'SANGER SAMPLE ID' }
      value { number }
      attribute { :sample_id }
    end

    factory :sanger_plate_id_column do
      name { :sanger_plate_id }
      heading { 'SANGER PLATE ID' }
      value { number }
      attribute { :barcode }
    end

    factory :sanger_tube_id_column do
      name { :sanger_tube_id }
      heading { 'SANGER TUBE ID' }
      value { number }
      attribute { :barcode }
    end

    factory :well_column do
      name { :well }
      heading { 'WELL' }
      value { number }
      attribute { :position }
    end

    factory :tag_group_column do
      name { :tag_group }
      heading { 'TAG GROUP' }
      value { "Tag Group #{number}" }
    end

    factory :tag_index_column do
      name { :tag_index }
      heading { 'TAG INDEX' }
      value { "Tag Index #{number}" }
    end

    factory :tag2_group_column do
      name { :tag2_group }
      heading { 'TAG2 GROUP (Fill in for dual Index Only)' }
      value { "Tag2 Group #{number}" }
    end

    factory :tag2_index_column do
      name { :tag2_index }
      heading { 'TAG2 INDEX (Fill in for dual Index Only)' }
      value { "Tag2 Index #{number}" }
    end

    factory :library_type_column do
      name { :library_type }
      heading { 'LIBRARY TYPE' }
      value { "LIBRARY TYPE #{number}" }
    end

    factory :reference_genome_column do
      name { :reference_genome }
      heading { 'REFERENCE GENOME' }
      value { "REFERENCE GENOME #{number}" }
    end

    factory :insert_size_from_column do
      name { :insert_size_from }
      heading { 'INSERT SIZE FROM' }
      value { number }
    end

    factory :insert_size_to_column do
      name { :insert_size_to }
      heading { 'INSERT SIZE TO' }
      value { number }
    end

    factory :donor_id_column do
      name { :donor_id }
      heading { 'DONOR ID (required for EGA)' }
      value { "DONOR ID #{number}" }
    end

    factory :retention_instruction_column do
      name { :retention_instruction }
      heading { 'RETENTION INSTRUCTION' }
      value { 'Long term storage' }
    end

    skip_create
  end
end
