# frozen_string_literal: true

# Disabling rubocop temporarily to preserve nice comments format
# rubocop:disable all

# We'll try and do this through the API with the live version
namespace :limber do
  desc 'Setup all the necessary limber records'
  task setup: %w[limber:create_submission_templates limber:create_searches limber:create_tag_templates]

<<<<<<< HEAD
  desc 'Create purposes for use in Limber pipelines'
  task create_purposes: :environment do
    purposes = [
      { name: 'LB Cherrypick', size: 96 },
      { name: 'scRNA Stock', size: 96 },
      { name: 'LBR Cherrypick', size: 96 },
      { name: 'LBB Cherrypick', size: 96 },
      { name: 'scRNA-384 Stock', size: 384 },
      { name: 'GBS Stock', size: 384 },
      { name: 'GnT Stock', size: 96 },
      { name: 'LTHR RT', size: 96 },
      { name: 'LTHR-384 RT', size: 384 }
    ]

    purposes.each do |purpose|
      name = purpose[:name]
      size = purpose[:size]

      # Caution: This is provided to help setting up limber development environments
      next if Purpose.where(name: name).exists?
      if Rails.env.production?
        abort(
          "
          #{name} plate purpose is missing.
          In production, this should be generated through Limber itself.
          Please ensure the latest version of Limber has been deployed before
          activating the submission templates. Limber should run:
          bundle exec rake config:generate automatically on deployment.
        "
        )
      end
      puts "Caution! Limber purposes do not exist. Creating #{name} plate."
      puts 'Other purposes will be generated by Limber'
      PlatePurpose::Input.create!(
        name: name,
        target_type: 'Plate',
        stock_plate: true,
        default_state: 'pending',
        barcode_printer_type_id: BarcodePrinterType.find_by(name: "#{size} Well Plate"),
        cherrypickable_target: true,
        cherrypick_direction: 'column',
        size: size,
        asset_shape: AssetShape.default
      )
    end

    unless Purpose.where(name: 'LB Lib PCR-XP').exists?
      PlatePurpose.create!(
        name: 'LB Lib PCR-XP',
        target_type: 'Plate',
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    # Added to ensure purpose exists before creating Limber Multiplexing
    # request type later. Otherwise request type has target purpose nil
    # and Limber Submissions fail to create final tubes for pipelines.
    unless Purpose.where(name: 'LB Lib Pool Norm').exists?
      IlluminaHtp::MxTubePurpose.create!(
        name: 'LB Lib Pool Norm',
        target_type: 'MultiplexedLibraryTube',
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '1D Tube'),
        cherrypickable_target: true,
        cherrypick_direction: 'column',
        size: 96,
        barcode_prefix: BarcodePrefix.find_by(prefix: 'NT')
      )
    end

    # Added to ensure purpose exists before creating the Limber Bespoke
    # Aggregation request type later.
    unless Purpose.where(name: 'LBC Stock').exists?
      PlatePurpose.create!(
        name: 'LBC Stock',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: true,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    # Added to ensure purpose exists before creating the Limber Bespoke
    # Chromium request type later.
    unless Purpose.where(name: 'LBC Cherrypick').exists?
      PlatePurpose.create!(
        name: 'LBC Cherrypick',
        target_type: 'Plate',
        stock_plate: false,
        input_plate: false,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'TR Stock 96').exists?
      TubeRack::Purpose.create!(
        name: 'TR Stock 96',
        target_type: 'TubeRack',
        stock_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96
      )
    end

    unless Purpose.where(name: 'TR Stock 48').exists?
      TubeRack::Purpose.create!(
        name: 'TR Stock 48',
        target_type: 'TubeRack',
        stock_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 48
      )
    end

    unless Purpose.where(name: 'Heron Lysed Tube Rack').exists?
      TubeRack::Purpose.create!(
        name: 'Heron Lysed Tube Rack',
        target_type: 'TubeRack',
        stock_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96
      )
    end

    unless Purpose.where(name: 'LDS Stock').exists?
      PlatePurpose.create!(
        name: 'LDS Stock',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'LDS Cherrypick').exists?
      PlatePurpose.create!(
        name: 'LDS Cherrypick',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: true,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'LHR Stock').exists?
      PlatePurpose.create!(
        name: 'LHR Stock',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: false,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'LHR Cherrypick').exists?
      PlatePurpose.create!(
        name: 'LHR Cherrypick',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: false,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: true,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'LHR RT').exists?
      PlatePurpose.create!(
        name: 'LHR RT',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: true,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'LHR-384 RT').exists?
      PlatePurpose.create!(
        name: 'LHR-384 RT',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '384 Well Plate'),
        cherrypickable_target: true,
        size: 384,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'Heron Lysed Plate').exists?
      PlatePurpose.create!(
        name: 'Heron Lysed Plate',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: true,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'LCA Blood Array').exists?
      PlatePurpose.create!(
        name: 'LCA Blood Array',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end

    unless Purpose.where(name: 'LCA Blood Bank').exists?
      PlatePurpose.create!(
        name: 'LCA Blood Bank',
        target_type: 'Plate',
        stock_plate: true,
        input_plate: true,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: false,
        size: 96,
        asset_shape: AssetShape.find_by(name: 'Standard')
      )
    end
  end

  desc 'Create the limber request types'
  task create_request_types: %i[environment create_purposes] do
    puts 'Creating request types...'
    ActiveRecord::Base.transaction do
      %w[WGS LCMB].each { |prefix| Limber::Helper::RequestTypeConstructor.new(prefix).build! }

      Limber::Helper::RequestTypeConstructor.new('pWGS-384', library_types: ['pWGS-384']).build!

      Limber::Helper::RequestTypeConstructor.new(
        'Duplex-Seq',
        library_types: ['Duplex-Seq', 'Targeted Nanoseq'],
        default_purposes: ['LDS Stock', 'LDS Cherrypick']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'PCR Free',
        library_types: ['HiSeqX PCR free', 'PCR Free 384', 'Chromium single cell CNV', 'DAFT-seq'],
        default_purposes: ['PF Cherrypicked']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'ISC',
        request_class: 'Pulldown::Requests::IscLibraryRequest',
        library_types: ['Agilent Pulldown', 'Twist Pulldown']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'GBS',
        request_class: 'IlluminaHtp::Requests::GbsRequest',
        library_types: ['GBS'],
        default_purposes: ['GBS Stock', 'GBS-96 stock'],
        for_multiplexing: true
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'RNAA',
        library_types: ['RNA PolyA'],
        default_purposes: ['LBR Cherrypick']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'RNAR',
        library_types: ['RNA Ribo'],
        default_purposes: ['LBR Cherrypick']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'RNAAG',
        library_types: ['RNA Poly A Globin'],
        default_purposes: ['LBR Cherrypick']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'RNARG',
        library_types: ['RNA Ribo Globin'],
        default_purposes: ['LBR Cherrypick']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'ReISC',
        request_class: 'Pulldown::Requests::ReIscLibraryRequest',
        library_types: ['Agilent Pulldown', 'Twist Pulldown'],
        default_purposes: ['LB Lib PCR-XP']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'scRNA',
        library_types: ['scRNA', 'GnT scRNA'],
        default_purposes: ['scRNA Stock', 'GnT Stock']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'scRNA-384',
        library_types: ['scRNA 384'],
        default_purposes: ['scRNA-384 Stock']
      ).build!

      # GnT Pipeline requires UAT
      Limber::Helper::RequestTypeConstructor.new(
        'GnT Picoplex',
        library_types: ['GnT Picoplex'],
        default_purposes: ['GnT Stock']
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'GnT MDA',
        library_types: ['GnT MDA'], # 'GnT scRNA' should be a default_purpose of 'scRNA'.
        default_purposes: ['GnT Stock'] # It requires default_purpose to accept an array.
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'PCR Bespoke',
        library_types: [
          'Manual Standard WGS (Plate)',
          'ChIP-Seq Auto',
          'TruSeq mRNA (RNA Seq)',
          'Small RNA (miRNA)',
          'RNA-seq dUTP eukaryotic',
          'RNA-seq dUTP prokaryotic',
          'Standard',
          'Ribozero RNA depletion',
          'Ribozero RNA-seq (Bacterial)',
          'Ribozero RNA-seq (HMR)',
          'TraDIS',
          'Chromium Visium',
          'Hi-C',
          'Haplotagging',
          'Chromium single cell HTO',
          'Chromium single cell surface protein'
        ],
        product_line: 'Bespoke',
        default_purposes: ['LBB Cherrypick'] # It requires default_purpose to accept an array.
      ).build!

      chromium_library_types = [
        'Chromium genome',
        'Chromium exome',
        'Chromium single cell',
        'Chromium single cell CNV',
        'Chromium single cell 3 prime v2',
        'Chromium single cell 3 prime v3',
        'Chromium single cell 5 prime',
        'Chromium single cell TCR',
        'Chromium single cell BCR'
      ]

      Limber::Helper::RequestTypeConstructor.new(
        'Chromium Bespoke',
        library_types: chromium_library_types,
        product_line: 'Bespoke',
        default_purposes: ['LBB Cherrypick', 'LBC Cherrypick'] # It requires default_purpose to accept an array.
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'PCR Free Bespoke',
        library_types: ['No PCR (Plate)', 'HiSeqX PCR free', 'DAFT-seq', 'TruSeq Custom Amplicon'],
        product_line: 'Bespoke',
        default_purposes: ['LBB Cherrypick'] # It requires default_purpose to accept an array.
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'Heron',
        request_class: 'IlluminaHtp::Requests::HeronRequest',
        library_types: [
          'PCR amplicon ligated adapters',
          'PCR amplicon ligated adapters 384',
          'PCR with TruSeq tails amplicon',
          'PCR with TruSeq tails amplicon 384',
          'Sanger_artic_v3_96',
          'Sanger_artic_v4_96'
        ],
        default_purposes: ['LHR RT', 'LHR-384 RT'] # It requires default_purpose to accept an array.
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'Heron LTHR',
        request_class: 'IlluminaHtp::Requests::HeronTailedRequest',
        library_types: [
          'PCR amplicon tailed adapters 96',
          'PCR amplicon tailed adapters 384',
          'Sanger_tailed_artic_v1_96',
          'Sanger_tailed_artic_v1_384'
        ],
        default_purposes: ['LTHR-384 RT', 'LTHR RT', 'LTHR Cherrypick']
      ).build!

      unless RequestType.where(key: 'limber_multiplexing').exists?
        RequestType.create!(
          name: 'Limber Multiplexing',
          key: 'limber_multiplexing',
          request_class_name: 'Request::Multiplexing',
          for_multiplexing: true,
          asset_type: 'Well',
          order: 2,
          initial_state: 'pending',
          billable: false,
          product_line: ProductLine.find_by(name: 'Illumina-Htp'),
          request_purpose: :standard,
          target_purpose: Purpose.find_by(name: 'LB Lib Pool Norm')
        )
      end

      unless RequestType.where(key: 'limber_bespoke_aggregation').exists?
        rt =
          RequestType.create!(
            name: 'Limber Bespoke Aggregation',
            key: 'limber_bespoke_aggregation',
            request_class_name: 'CustomerRequest',
            for_multiplexing: false,
            asset_type: 'Well',
            order: 0,
            initial_state: 'pending',
            billable: false,
            product_line: ProductLine.find_by(name: 'Bespoke'),
            request_purpose: :standard
          )

        # NB. These library types should exist by this point because they were
        # passed to the Chromium Bespoke request type further up.
        chromium_library_types.each { |name| rt.library_types << LibraryType.find_or_create_by!(name: name) }
        rt.acceptable_plate_purposes = Purpose.where(name: 'LBC Stock')
      end

      Limber::Helper::RequestTypeConstructor.new(
        'Cardinal',
        library_types: ['Cardinal'],
        default_purposes: ['LCA Blood Array']
      ).build!
      Limber::Helper::RequestTypeConstructor.new(
        'Cardinal Banking',
        library_types: ['Cardinal Banking'],
        default_purposes: ['LCA Blood Bank']
      ).build!
    end
=======
  task create_plates: :environment do
    puts '📣 limber:create_plates no longer generates records. These are made automatically when seeding development.'
  end

  desc 'Create the limber request types'
  task create_request_types: %i[environment] do
    puts '📣 limber:create_request_types no longer generates records. These are made automatically when seeding development.'
>>>>>>> 44cbe9981a139925aef906532c881b52b472ddc3
  end

  desc 'Create the limber searches'
  task create_searches: [:environment] do
    Search::FindPlates.create_with(default_parameters: { limit: 30 }).find_or_create_by!(name: 'Find plates')
    Search::FindTubes.create_with(default_parameters: { limit: 30 }).find_or_create_by!(name: 'Find tubes')
  end

  desc 'Create tag plate lots and templates'
  task create_tag_templates: :environment do
    tp = QcablePlatePurpose.find_or_create_by!(name: 'Tag Plate', target_type: 'Plate', default_state: 'created')
    rp = QcablePlatePurpose.find_or_create_by!(name: 'Reporter Plate', target_type: 'Plate', default_state: 'created')
    itt = QcableTubePurpose.find_or_create_by!(name: 'Tag 2 Tube', target_type: 'Tube')
    pstp =
      QcablePlatePurpose.find_or_create_by!(
        name: 'Pre Stamped Tag Plate',
        target_type: 'Plate',
        default_state: 'available'
      )
    btp =
      QcablePlatePurpose.find_or_create_by!(
        name: 'Tag Plate - 384',
        target_type: 'Plate',
        default_state: 'available',
        size: 384
      )
    LotType.find_or_create_by!(name: 'IDT Tags', template_class: 'TagLayoutTemplate', target_purpose: tp)
    LotType.find_or_create_by!(name: 'IDT Reporters', template_class: 'PlateTemplate', target_purpose: rp)
    LotType.find_or_create_by!(name: 'Tag 2 Tubes', template_class: 'Tag2LayoutTemplate', target_purpose: itt)
    LotType.find_or_create_by!(name: 'Pre Stamped Tags', template_class: 'TagLayoutTemplate', target_purpose: pstp)
    LotType.find_or_create_by!(name: 'Tag 2 Tubes', template_class: 'Tag2LayoutTemplate', target_purpose: itt)
    LotType.find_or_create_by!(name: 'Pre Stamped Tags - 384', template_class: 'TagLayoutTemplate', target_purpose: btp)
  end

  desc 'Create tag layout templates'
  task create_tag_layout_templates: :environment do
    i7_group = TagGroup.find_by(name: 'IDT for Illumina i7 UDI v1')
    i5_group = TagGroup.find_by(name: 'IDT for Illumina i5 UDI v1')

    if i7_group.nil? || i5_group.nil?
      puts 'Could not find tag groups to create templates. Skipping.'
    else
      puts 'Creating tag Group - IDT for Illumina v1 - 384 Quadrant'
      TagLayoutTemplate
        .create_with(
          tag_group: i7_group,
          tag2_group: i5_group,
          walking_algorithm: 'TagLayout::Quadrants',
          direction_algorithm: 'TagLayout::InColumns'
        )
        .find_or_create_by!(name: 'IDT for Illumina v1 - 384 Quadrant')
    end
  end

  desc 'Create the limber submission templates'
  task create_submission_templates: [
         :environment,
         'sequencing:novaseq:setup',
         'sequencing:gbs_miseq:setup',
         'sequencing:heron_miseq:setup'
       ] do
    puts 'Creating submission templates....'

    base_list = %w[
      illumina_b_hiseq_2500_paired_end_sequencing
      illumina_b_hiseq_2500_single_end_sequencing
      illumina_b_miseq_sequencing
      illumina_b_hiseq_v4_paired_end_sequencing
      illumina_b_hiseq_x_paired_end_sequencing
      illumina_htp_hiseq_4000_paired_end_sequencing
      illumina_htp_hiseq_4000_single_end_sequencing
      illumina_htp_novaseq_6000_paired_end_sequencing
    ]
    full_list = base_list + %w[illumina_c_hiseq_v4_single_end_sequencing]

    # HiSeqX is filtered out for non-WGS library types due to specific restrictions
    # that limit the use of the technology to WGS.
    base_without_hiseq = base_list - ['illumina_b_hiseq_x_paired_end_sequencing']
    st_params = {
      'WGS' => {
        sequencing_list: base_list
      },
      'ISC' => {
        sequencing_list: base_list
      },
      'ReISC' => {
        sequencing_list: base_list
      },
      'scRNA' => {
        sequencing_list: base_without_hiseq
      },
      'scRNA-384' => {
        sequencing_list: base_without_hiseq
      },
      'RNAA' => {
        sequencing_list: base_without_hiseq
      },
      'RNAR' => {
        sequencing_list: base_without_hiseq
      },
      'RNAAG' => {
        sequencing_list: base_without_hiseq
      },
      'RNARG' => {
        sequencing_list: base_without_hiseq
      },
      'PCR Free' => {
        sequencing_list: base_list,
        catalogue_name: 'PFHSqX'
      },
      'GnT Picoplex' => {
        sequencing_list: base_without_hiseq
      },
      'pWGS-384' => {
        sequencing_list: %w[
          illumina_b_hiseq_x_paired_end_sequencing
          illumina_htp_novaseq_6000_paired_end_sequencing
          illumina_b_miseq_sequencing
        ],
        omit_library_templates: true
      }
    }

    ActiveRecord::Base.transaction do
      st_params.each do |prefix, params|
        catalogue_name = (params[:catalogue_name] || prefix)
        catalogue =
          ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: catalogue_name)
        Limber::Helper::TemplateConstructor.new(
          prefix: prefix,
          catalogue: catalogue,
          sequencing_keys: params[:sequencing_list]
        ).build!
        unless params[:omit_library_templates]
          Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: prefix, catalogue: catalogue).build!
          Limber::Helper::LibraryAndMultiplexingTemplateConstructor.new(prefix: prefix, catalogue: catalogue).build!
        end
      end

      heron_catalogue = ProductCatalogue.find_or_create_by!(name: 'Heron')
      Limber::Helper::TemplateConstructor.new(prefix: 'Heron', catalogue: heron_catalogue, sequencing_keys: base_list)
        .build!
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'Heron', catalogue: heron_catalogue).build!
      Limber::Helper::LibraryAndMultiplexingTemplateConstructor.new(prefix: 'Heron', catalogue: heron_catalogue).build!

      heron_lthr_catalogue = ProductCatalogue.find_or_create_by!(name: 'Heron LTHR')
      Limber::Helper::TemplateConstructor.new(
        prefix: 'Heron LTHR',
        catalogue: heron_lthr_catalogue,
        sequencing_keys: base_list,
        role: 'LTHR'
      ).build!
      Limber::Helper::LibraryOnlyTemplateConstructor.new(
        prefix: 'Heron LTHR',
        catalogue: heron_lthr_catalogue,
        role: 'LTHR'
      ).build!
      Limber::Helper::LibraryAndMultiplexingTemplateConstructor.new(
        prefix: 'Heron LTHR',
        catalogue: heron_lthr_catalogue,
        role: 'LTHR'
      ).build!

      unless SubmissionTemplate.find_by(name: 'Limber - Heron LTHR - Automated')
        SubmissionTemplate.create!(
          name: 'Limber - Heron LTHR - Automated',
          submission_class_name: 'LinearSubmission',
          submission_parameters: {
            request_type_ids_list: [
              RequestType.where(key: 'limber_heron_lthr').ids,
              RequestType.where(key: 'limber_multiplexing').ids,
              RequestType.where(key: 'illumina_htp_novaseq_6000_paired_end_sequencing').ids
            ],
            project_id: Limber::Helper.find_project('Project Heron').id
          },
          product_line: ProductLine.find_by!(name: 'Illumina-HTP'),
          product_catalogue: ProductCatalogue.find_by!(name: 'Generic')
        )
      end

      lcbm_catalogue =
        ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'LCMB')
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'LCMB', catalogue: lcbm_catalogue).build!

      duplex_seq_catalogue =
        ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Duplex-Seq')
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'Duplex-Seq', catalogue: duplex_seq_catalogue).build!

      mda_catalogue = ProductCatalogue.find_or_create_by!(name: 'GnT MDA')
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'GnT MDA', catalogue: mda_catalogue).build!

      gbs_catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'GBS')
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'GBS', catalogue: gbs_catalogue).build!

      cardinal_catalogue =
        ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Cardinal')

      catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Generic')
      Limber::Helper::TemplateConstructor.new(prefix: 'Multiplexing', catalogue: catalogue, sequencing_keys: base_list)
        .build!

      ## Bespoke Pipelines ##
      generic_pcr =
        ProductCatalogue.create_with(selection_behaviour: 'LibraryDriven').find_or_create_by!(name: 'GenericPCR')
      generic_no_pcr =
        ProductCatalogue.create_with(selection_behaviour: 'LibraryDriven').find_or_create_by!(name: 'GenericNoPCR')
      chromium = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Chromium')

      Limber::Helper::TemplateConstructor.new(
        prefix: 'PCR Bespoke',
        name: 'PCR',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: generic_pcr,
        sequencing_keys: full_list
      ).build!
      Limber::Helper::LibraryOnlyTemplateConstructor.new(
        prefix: 'PCR Bespoke',
        name: 'PCR',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: generic_pcr
      ).build!
      Limber::Helper::LibraryAndMultiplexingTemplateConstructor.new(
        prefix: 'PCR Bespoke',
        name: 'PCR',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: generic_pcr
      ).build!

      Limber::Helper::TemplateConstructor.new(
        prefix: 'PCR Free Bespoke',
        name: 'PCR Free',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: generic_no_pcr,
        sequencing_keys: full_list
      ).build!
      Limber::Helper::LibraryOnlyTemplateConstructor.new(
        prefix: 'PCR Free Bespoke',
        name: 'PCR Free',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: generic_no_pcr
      ).build!
      Limber::Helper::LibraryAndMultiplexingTemplateConstructor.new(
        prefix: 'PCR Free Bespoke',
        name: 'PCR Free',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: generic_no_pcr
      ).build!

      Limber::Helper::TemplateConstructor.new(
        prefix: 'Chromium Bespoke',
        name: 'Chromium',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: chromium,
        sequencing_keys: full_list,
        role: 'Chromium'
      ).build!
      Limber::Helper::LibraryOnlyTemplateConstructor.new(
        prefix: 'Chromium Bespoke',
        name: 'Chromium',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: chromium,
        role: 'Chromium'
      ).build!
      Limber::Helper::LibraryAndMultiplexingTemplateConstructor.new(
        prefix: 'Chromium Bespoke',
        name: 'Chromium',
        pipeline: 'Limber-Bespoke',
        product_line: 'Bespoke',
        catalogue: chromium,
        role: 'Chromium'
      ).build!

      unless SubmissionTemplate.find_by(name: 'Limber - Cardinal')
        SubmissionTemplate.create!(
          name: 'Limber - Cardinal',
          submission_class_name: 'LinearSubmission',
          submission_parameters: {
            request_type_ids_list: [RequestType.where(key: 'limber_cardinal').ids],
            project_id: Limber::Helper.find_project('Project Cardinal').id
          },
          product_line: ProductLine.find_or_create_by!(name: 'Cardinal'),
          product_catalogue: cardinal_catalogue
        )
      end

      unless SubmissionTemplate.find_by(name: 'Limber - Cardinal cell banking')
        SubmissionTemplate.create!(
          name: 'Limber - Cardinal cell banking',
          submission_class_name: 'LinearSubmission',
          submission_parameters: {
            request_type_ids_list: [RequestType.where(key: 'limber_cardinal_banking').ids],
            project_id: Limber::Helper.find_project('Project Cardinal').id
          },
          product_line: ProductLine.find_or_create_by!(name: 'Cardinal'),
          product_catalogue: cardinal_catalogue
        )
      end

      ## end ##
      unless SubmissionTemplate.find_by(name: 'MiSeq for GBS')
        SubmissionTemplate.create!(
          name: 'MiSeq for GBS',
          submission_class_name: 'AutomatedOrder',
          submission_parameters: {
            request_type_ids_list: [RequestType.where(key: 'gbs_miseq_sequencing').ids]
          },
          product_line: ProductLine.find_by!(name: 'Illumina-HTP'),
          product_catalogue: ProductCatalogue.find_by!(name: 'Generic')
        )
      end

      unless SubmissionTemplate.find_by(name: 'Limber-Bespoke - Aggregation')
        SubmissionTemplate.create!(
          name: 'Limber-Bespoke - Aggregation',
          submission_class_name: 'LinearSubmission',
          submission_parameters: {
            request_type_ids_list: [RequestType.where(key: 'limber_bespoke_aggregation').ids]
          },
          product_line: ProductLine.find_by!(name: 'Bespoke'),
          product_catalogue: ProductCatalogue.find_by!(name: 'Generic')
        )
      end

      unless SubmissionTemplate.find_by(name: 'MiSeq for Heron')
        SubmissionTemplate.create!(
          name: 'MiSeq for Heron',
          submission_class_name: 'AutomatedOrder',
          submission_parameters: {
            request_type_ids_list: [RequestType.where(key: 'heron_miseq_sequencing').ids]
          },
          product_line: ProductLine.find_by!(name: 'Illumina-HTP'),
          product_catalogue: ProductCatalogue.find_by!(name: 'Heron')
        )
      end
    end
  end
end

# rubocop:enable all
