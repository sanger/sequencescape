# frozen_string_literal: true

FactoryBot.define do
  factory :request_metadata, class: 'Request::Metadata' do
    read_length { 76 }
    customer_accepts_responsibility { false }
  end

  factory :request_traction_grid_ion_metadata, class: 'Request::Traction::GridIon::Metadata' do
    library_type { 'Rapid' }
    data_type { 'basecalls and raw data' }
    owner factory: %i[request_traction_grid_ion]
  end

  # Automatically generated request types
  factory(:request_metadata_for_request_type_, parent: :request_metadata)

  # Pre-HiSeq sequencing
  factory :request_metadata_for_standard_sequencing, parent: :request_metadata do
    fragment_size_required_from { 1 }
    fragment_size_required_to { 21 }
    read_length { 76 }

    factory :request_metadata_for_single_ended_sequencing
    factory :request_metadata_for_paired_end_sequencing
  end

  factory :request_metadata_for_standard_sequencing_with_read_length,
          parent: :request_metadata,
          class: 'SequencingRequest::Metadata' do
    fragment_size_required_from { 1 }
    fragment_size_required_to { 21 }
    read_length { 76 }
    owner factory: %i[sequencing_request]
  end

  # HiSeq sequencing
  factory :request_metadata_for_hiseq_sequencing, parent: :request_metadata do
    fragment_size_required_from { 1 }
    fragment_size_required_to { 21 }
    read_length { 100 }

    factory :request_metadata_for_hiseq_paired_end_sequencing
    factory :request_metadata_for_single_ended_hi_seq_sequencing
  end

  factory :request_metadata_for_miseq_sequencing, parent: :request_metadata do
    read_length { 25 }
  end

  factory :hiseq_x_request_metadata, parent: :request_metadata do
    fragment_size_required_from { 1 }
    fragment_size_required_to { 21 }
    read_length { 100 }

    factory :request_metadata_for_illumina_a_hiseq_x_paired_end_sequencing
    factory :request_metadata_for_illumina_b_hiseq_x_paired_end_sequencing
    factory :request_metadata_for_hiseq_x_paired_end_sequencing
  end

  ('a'..'c').each do |p|
    factory(
      :"request_metadata_for_illumina_#{p}_single_ended_sequencing",
      parent: :request_metadata_for_standard_sequencing
    ) {}
    factory(
      :"request_metadata_for_illumina_#{p}_paired_end_sequencing",
      parent: :request_metadata_for_standard_sequencing
    ) {}

    # HiSeq sequencing
    factory :"request_metadata_for_illumina_#{p}_hiseq_sequencing", parent: :request_metadata do
      fragment_size_required_from { 1 }
      fragment_size_required_to { 21 }
      read_length { 100 }
    end
    factory(
      :"request_metadata_for_illumina_#{p}_hiseq_paired_end_sequencing",
      parent: :request_metadata_for_hiseq_sequencing
    ) {}
    factory(
      :"request_metadata_for_illumina_#{p}_single_ended_hi_seq_sequencing",
      parent: :request_metadata_for_hiseq_sequencing
    ) {}
  end

  # Library manufacture
  factory :request_metadata_for_library_manufacture, parent: :request_metadata do
    fragment_size_required_from { 1 }
    fragment_size_required_to { 20 }
    library_type { 'Standard' }

    # TODO: [JG] These are all redundnant,and are a symptom of both our tests dependency
    # on sangerisms within the code,
    factory :request_metadata_for_library_creation
    factory :request_metadata_for_illumina_c_library_creation
    factory :request_metadata_for_multiplexed_library_creation
    factory :request_metadata_for_mx_library_preparation_new
    factory :request_metadata_for_illumina_b_multiplexed_library_creation
    factory :request_metadata_for_illumina_c_multiplexed_library_creation
    factory :request_metadata_for_pulldown_library_creation
    factory :request_metadata_for_pulldown_multiplex_library_preparation

    factory :request_metadata_for_gbs, class: 'IlluminaHtp::Requests::GbsRequest::Metadata' do
      primer_panel_name { create(:primer_panel).name }
      owner factory: %i[gbs_request]
    end

    factory :request_metadata_for_heron, class: 'IlluminaHtp::Requests::HeronRequest::Metadata' do
      primer_panel_name { create(:primer_panel).name }
      owner factory: %i[heron_request]
    end
  end

  # Bait libraries
  factory(:request_metadata_for_bait_pulldown, parent: :request_metadata) do
    bait_library_id { |_bl| create(:bait_library).id }
  end

  # set default  metadata factories to every request types which have been defined yet
  RequestType.find_each do |rt|
    factory_name = :"request_metadata_for_#{rt.name.downcase.gsub(/[^a-z]+/, '_')}"
    next if FactoryBot.factories.registered?(factory_name)

    factory(factory_name, parent: :request_metadata)
  end
end
