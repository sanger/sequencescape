# frozen_string_literal: true

# Disabling rubocop temporarily to preserve nice comments format

# We'll try and do this through the API with the live version
namespace :limber do
  desc 'Setup all the necessary limber records'
  task setup: %w[limber:create_submission_templates limber:create_searches limber:create_tag_templates]

  task create_plates: :environment do
    puts '📣 limber:create_plates no longer generates records. These are made automatically when seeding development.'
  end

  desc 'Create the limber request types'
  task create_request_types: %i[environment] do
    puts '📣 limber:create_request_types no longer generates records. These are made automatically when seeding development.' # rubocop:disable Layout/LineLength
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
      TagLayoutTemplate.create_with(
        tag_group: i7_group,
        tag2_group: i5_group,
        walking_algorithm: 'TagLayout::Quadrants',
        direction_algorithm: 'TagLayout::InColumns'
      ).find_or_create_by!(name: 'IDT for Illumina v1 - 384 Quadrant')
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

    # rubocop:todo Metrics/BlockLength
    ActiveRecord::Base.transaction do
      st_params.each do |prefix, params|
        catalogue_name = params[:catalogue_name] || prefix
        catalogue =
          ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: catalogue_name)
        Limber::Helper::TemplateConstructor.new(
          prefix: prefix,
          catalogue: catalogue,
          sequencing_keys: params[:sequencing_list]
        ).build!
        unless params[:omit_library_templates]
          Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix:, catalogue:).build!
          Limber::Helper::LibraryAndMultiplexingTemplateConstructor.new(prefix:, catalogue:).build!
        end
      end

      # rubocop:enable Metrics/BlockLength
      heron_catalogue = ProductCatalogue.find_or_create_by!(name: 'Heron')
      Limber::Helper::TemplateConstructor.new(
        prefix: 'Heron',
        catalogue: heron_catalogue,
        sequencing_keys: base_list
      ).build!
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

      heron_lthr_catalogue = ProductCatalogue.find_or_create_by!(name: 'Heron LTHR')
      Limber::Helper::TemplateConstructor.new(
        prefix: 'Heron LTHR V2',
        catalogue: heron_lthr_catalogue,
        sequencing_keys: base_list,
        role: 'LTHR'
      ).build!
      Limber::Helper::LibraryOnlyTemplateConstructor.new(
        prefix: 'Heron LTHR V2',
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

      unless SubmissionTemplate.find_by(name: 'Limber - Heron LTHR V2 - Automated')
        SubmissionTemplate.create!(
          name: 'Limber - Heron LTHR V2 - Automated',
          submission_class_name: 'LinearSubmission',
          submission_parameters: {
            request_type_ids_list: [
              RequestType.where(key: 'limber_heron_lthr_v2').ids,
              RequestType.where(key: 'illumina_htp_novaseq_6000_paired_end_sequencing').ids
            ],
            project_id: Limber::Helper.find_project('Project Heron').id
          },
          product_line: ProductLine.find_by!(name: 'Illumina-HTP'),
          product_catalogue: ProductCatalogue.find_by!(name: 'Generic')
        )
      end

      duplex_seq_catalogue =
        ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Duplex-Seq')
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'Duplex-Seq', catalogue: duplex_seq_catalogue).build!

      mda_catalogue = ProductCatalogue.find_or_create_by!(name: 'GnT MDA')
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'GnT MDA', catalogue: mda_catalogue).build!

      gbs_catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'GBS')
      Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'GBS', catalogue: gbs_catalogue).build!

      catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Generic')
      Limber::Helper::TemplateConstructor.new(
        prefix: 'Multiplexing',
        catalogue: catalogue,
        sequencing_keys: base_list
      ).build!

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
