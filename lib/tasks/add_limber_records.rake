# We'll try and do this through the API with the live version

namespace :limber do
  desc 'Create the Limber cherrypick plate'
  task create_plates: :environment do
    ['LB Cherrypick', 'scRNA Stock', 'LBR Cherrypick'].each do |name|
      # Caution: This is provided to help setting up limber development environments
      next if Purpose.where(name: name).exists?
      puts "Caution! Limber purposes do not exist. Creating #{name} plate."
      puts 'Other purposes will be generated by Limber'
      PlatePurpose::Input.create!(
        name: name,
        target_type: 'Plate',
        stock_plate: true,
        default_state: 'pending',
        barcode_printer_type_id: BarcodePrinterType.find_by(name: '96 Well Plate'),
        cherrypickable_target: true,
        cherrypick_direction: 'column',
        size: 96,
        asset_shape: AssetShape.default,
        barcode_for_tecan: 'ean13_barcode'
      )
    end
  end

  desc 'Create the limber request types'
  task create_request_types: [:environment, :create_plates] do
    puts 'Creating request types...'
    ActiveRecord::Base.transaction do
      ['WGS', 'LCMB'].each do |prefix|
        Limber::Helper::RequestTypeConstructor.new(prefix).build!
      end
      Limber::Helper::RequestTypeConstructor.new('PCR Free', default_purpose: 'PF Cherrypicked').build!

      Limber::Helper::RequestTypeConstructor.new(
        'ISC',
        request_class: 'Pulldown::Requests::IscLibraryRequest',
        library_types: 'Agilent Pulldown'
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'RNAA',
        library_types: ['RNA PolyA'],
        default_purpose: 'LBR Cherrypick'
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'ReISC',
        request_class: 'Pulldown::Requests::ReIscLibraryRequest',
        library_types: ['Agilent Pulldown'],
        default_purpose: 'LB Lib PCR-XP'
      ).build!

      Limber::Helper::RequestTypeConstructor.new(
        'scRNA',
        library_types: ['scRNA'],
        default_purpose: 'scRNA Stock'
      ).build!

      unless RequestType.where(key: 'limber_multiplexing').exists?
        RequestType.create!(
          name: 'Limber Multiplexing',
          key: 'limber_multiplexing',
          request_class_name: 'Request::Multiplexing',
          for_multiplexing: true,
          workflow: Submission::Workflow.find_by(name: 'Next-gen sequencing'),
          asset_type: 'Well',
          order: 2,
          initial_state: 'pending',
          billable: false,
          product_line: ProductLine.find_by(name: 'Illumina-Htp'),
          request_purpose: :standard,
          target_purpose: Purpose.find_by(name: 'LB Lib Pool Norm')
        )
      end
    end
  end

  desc 'Create the limber submission templates'
  task create_submission_templates: [:environment, :create_request_types] do
    puts 'Creating submission templates....'
    ActiveRecord::Base.transaction do
      %w(WGS ISC ReISC).each do |prefix|
        catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: prefix)
        Limber::Helper::TemplateConstructor.new(prefix: prefix, catalogue: catalogue).build!
      end
      'PCR Free'.tap do |prefix|
        catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'PFHSqX')
        Limber::Helper::TemplateConstructor.new(
          name: prefix,
          role: prefix,
          type: "limber_#{prefix.downcase.tr(' ', '_')}",
          catalogue: catalogue
        ).build!
      end
      ['scRNA', 'RNAA'].each do |prefix|
        catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: prefix)
        Limber::Helper::TemplateConstructor.new(
          name: prefix,
          role: prefix,
          type: "limber_#{prefix.downcase.tr(' ', '_')}",
          catalogue: catalogue,
          sequencing: Limber::Helper::ACCEPTABLE_SEQUENCING_REQUESTS - ['illumina_b_hiseq_x_paired_end_sequencing']
        ).build!
      end
    end
    lcbm_catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'LCMB')
    Limber::Helper::LibraryOnlyTemplateConstructor.new(prefix: 'LCMB', catalogue: lcbm_catalogue).build!
    catalogue = ProductCatalogue.create_with(selection_behaviour: 'SingleProduct').find_or_create_by!(name: 'Generic')
    Limber::Helper::TemplateConstructor.new(prefix: 'Multiplexing', catalogue: catalogue).build!
  end
end
