# frozen_string_literal: true

ActiveRecord::Base.transaction do
  pipeline_name = 'Illumina-B STD'

  if Rails.env.cucumber?
    RecordLoader::TubePurposeLoader.new(
      files: %w[002_illumina_b_legacy_purposes 004_illumina_htp_legacy_purposes]
    ).create!
    RecordLoader::PlatePurposeLoader.new(
      files: %w[002_illumina_b_legacy_purposes 004_illumina_htp_legacy_purposes]
    ).create!
  end

  # For B
  shared_options_b = {
    asset_type: 'Well',
    order: 1,
    initial_state: 'pending',
    billable: true,
    product_line_id: ProductLine.find_by(name: 'Illumina-B'),
    no_target_asset: false
  }

  shared_options_a = shared_options_b.clone.merge(product_line_id: ProductLine.find_by(name: 'Illumina-A'))

  [
    {
      name: 'Illumina-B STD',
      key: pipeline_name.downcase.gsub(/\W+/, '_'),
      target_purpose: Purpose.find_by!(name: 'ILB_STD_MX'),
      for_multiplexing: true,
      request_class_name: 'IlluminaB::Requests::StdLibraryRequest'
    },
    {
      key: 'illumina_b_shared',
      name: 'Shared Library Creation',
      request_class_name: 'IlluminaHtp::Requests::SharedLibraryPrep',
      for_multiplexing: false,
      no_target_asset: false
    },
    {
      key: 'illumina_b_pool',
      name: 'Illumina-B Pooled',
      request_class_name: 'IlluminaHtp::Requests::LibraryCompletion',
      for_multiplexing: true,
      no_target_asset: false,
      target_purpose: Purpose.find_by!(name: 'Lib Pool Norm')
    },
    {
      key: 'illumina_b_pippin',
      name: 'Illumina-B Pippin',
      request_class_name: 'IlluminaHtp::Requests::LibraryCompletion',
      for_multiplexing: true,
      no_target_asset: false,
      target_purpose: Purpose.find_by!(name: 'Lib Pool SS-XP-Norm')
    }
  ].each { |request_type_options| RequestType.create!(shared_options_b.merge(request_type_options)) }

  Pulldown::PlatePurposes.create_purposes(Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.last)

  [
    {
      key: 'illumina_a_shared',
      name: 'Illumina-A Shared Library Creation',
      request_class_name: 'IlluminaHtp::Requests::SharedLibraryPrep',
      acceptable_purposes: [Purpose.find_by(name: 'Cherrypicked')],
      for_multiplexing: false,
      no_target_asset: false
    },
    {
      key: 'illumina_a_pool',
      name: 'Illumina-A Pooled',
      request_class_name: 'IlluminaHtp::Requests::LibraryCompletion',
      for_multiplexing: true,
      no_target_asset: false,
      target_purpose: Purpose.find_by!(name: 'Lib Pool Norm')
    },
    {
      key: 'illumina_a_isc',
      name: 'Illumina-A ISC',
      request_class_name: 'Pulldown::Requests::IscLibraryRequestPart',
      acceptable_purposes: [Purpose.find_by(name: 'Lib PCR-XP')],
      for_multiplexing: true,
      no_target_asset: false,
      target_purpose: Purpose.find_by(name: 'Cap Lib Pool Norm')
    }
  ].each { |request_type_options| RequestType.create!(shared_options_a.merge(request_type_options)) }

  def sequencing_request_type_names_for(pipeline)
    [
      'Single ended sequencing',
      'Single ended hi seq sequencing',
      'Paired end sequencing',
      'HiSeq Paired end sequencing',
      'HiSeq 2500 Single end sequencing',
      'HiSeq 2500 Paired end sequencing'
    ].map { |s| "#{pipeline} #{s}" }
  end

  [
    {
      pulldown_requests: ['Illumina-B STD'],
      defaults: {
        'library_type' => 'Standard',
        'fragment_size_required_from' => 300,
        'fragment_size_required_to' => 500
      },
      name: 'Multiplexed WGS'
    },
    {
      pulldown_requests: ['Shared Library Creation', 'Illumina-B Pooled'],
      defaults: {
        'library_type' => 'Standard',
        'fragment_size_required_from' => 300,
        'fragment_size_required_to' => 500
      },
      name: 'Pooled PATH',
      label: 'ILB PATH'
    },
    {
      pulldown_requests: ['Shared Library Creation', 'Illumina-B Pippin'],
      defaults: {
        'library_type' => 'Standard',
        'fragment_size_required_from' => 300,
        'fragment_size_required_to' => 500
      },
      name: 'Pippin PATH',
      label: 'ILB PATH'
    },
    {
      pulldown_requests: ['Shared Library Creation', 'Illumina-B Pooled'],
      defaults: {
        'library_type' => 'Standard',
        'fragment_size_required_from' => 300,
        'fragment_size_required_to' => 500
      },
      name: 'Pooled HWGS',
      label: 'ILB HWGS'
    },
    {
      pulldown_requests: ['Shared Library Creation', 'Illumina-B Pippin'],
      defaults: {
        'library_type' => 'Standard',
        'fragment_size_required_from' => 300,
        'fragment_size_required_to' => 500
      },
      name: 'Pippin HWGS',
      label: 'ILB HWGS'
    }
  ].each do |request_type_options|
    defaults = request_type_options[:defaults]
    pulldown_request_types =
      request_type_options[:pulldown_requests].map { |request_type_name| RequestType.find_by!(name: request_type_name) }

    RequestType
      .where(name: sequencing_request_type_names_for('Illumina-B'))
      .find_each do |sequencing_request_type|
        submission = LinearSubmission.new
        submission.request_type_ids = [pulldown_request_types.map(&:id), sequencing_request_type.id].flatten
        submission.info_differential = nil
        submission.request_options = defaults
        submission.request_type_ids = [pulldown_request_types.map(&:id), sequencing_request_type.id].flatten
      end
  end

  [
    {
      pulldown_requests: ['Illumina-A Shared Library Creation', 'Illumina-A ISC'],
      defaults: {
        'library_type' => 'Standard',
        'fragment_size_required_from' => 300,
        'fragment_size_required_to' => 500,
        'pre_capture_plex_level' => '8'
      },
      name: 'HTP ISC',
      label: 'ILA ISC'
    }
  ].each do |request_type_options|
    defaults = request_type_options[:defaults]
    pulldown_request_types =
      request_type_options[:pulldown_requests].map { |request_type_name| RequestType.find_by!(name: request_type_name) }

    RequestType
      .where(name: sequencing_request_type_names_for('Illumina-A'))
      .find_each do |sequencing_request_type|
        submission = LinearSubmission.new
        submission.request_type_ids = [pulldown_request_types.map(&:id), sequencing_request_type.id].flatten
        submission.info_differential = nil
        submission.request_options = defaults

        submission.request_type_ids = [pulldown_request_types.map(&:id), sequencing_request_type.id].flatten
      end
  end

  RequestType.find_by(key: 'illumina_b_shared').acceptable_purposes << Purpose.find_by(name: 'Cherrypicked')
  RequestType.create!(
    key: 'illumina_a_re_isc',
    name: 'Illumina-A ReISC',
    asset_type: 'Well',
    initial_state: 'pending',
    order: 1,
    request_class_name: 'Pulldown::Requests::IscLibraryRequest',
    for_multiplexing: true,
    product_line: ProductLine.find_by(name: 'Illumina-A'),
    target_purpose: Purpose.find_by(name: 'Standard MX')
  ) do |rt|
    rt.acceptable_purposes << Purpose.find_by!(name: 'Lib PCR-XP')
    RequestType::Validator.create!(
      request_type: rt,
      request_option: 'library_type',
      valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
    )
  end

  RequestType.create!(
    name: 'Illumina-HTP Library Creation',
    key: 'illumina_htp_library_creation',
    asset_type: 'Well',
    order: 1,
    initial_state: 'pending',
    multiples_allowed: false,
    request_class_name: 'IlluminaHtp::Requests::LibraryCompletion',
    morphology: 0,
    for_multiplexing: true,
    billable: false,
    product_line: ProductLine.find_by!(name: 'Illumina-B')
  ) do |rt|
    rt.pooling_method =
      RequestType::PoolingMethod.create!(pooling_behaviour: 'PlateRow', pooling_options: { pool_count: 8 })
    rt.acceptable_purposes << Purpose.find_by!(name: 'PF Cherrypicked')
    RequestType::Validator.create!(
      request_type: rt,
      request_option: 'library_type',
      valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
    )
    rt.library_types << LibraryType.find_or_create_by(name: 'HiSeqX PCR free')
  end

  RequestType.create!(
    name: 'HTP PCR Free Library',
    key: 'htp_pcr_free_lib',
    asset_type: 'Well',
    deprecated: false,
    initial_state: 'pending',
    for_multiplexing: true,
    morphology: 0,
    multiples_allowed: false,
    no_target_asset: false,
    order: 1,
    pooling_method: RequestType::PoolingMethod.find_by!(pooling_behaviour: 'PlateRow'),
    request_purpose: :standard,
    request_class_name: 'IlluminaHtp::Requests::StdLibraryRequest',
    product_line: ProductLine.find_by!(name: 'Illumina-HTP')
  ) { |rt| rt.acceptable_purposes << Purpose.find_by!(name: 'PF Cherrypicked') }

  RequestType.find_by!(key: 'illumina_b_hiseq_x_paired_end_sequencing').acceptable_purposes << PlatePurpose.create!(
    name: 'Strip Tube Purpose',
    target_type: 'StripTube',
    stock_plate: false,
    cherrypickable_target: false,
    barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
    cherrypick_direction: 'column',
    size: 8,
    asset_shape: AssetShape.find_by(name: 'StripTubeColumn')
  )
end
