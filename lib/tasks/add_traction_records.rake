# frozen_string_literal: true
# We'll try and do this through the API with the live version

namespace :traction do
  desc 'Create the traction request types'
  task create_request_types: [:environment] do
    puts 'Creating request types...'

    ActiveRecord::Base.transaction do
      unless RequestType.exists?(key: 'traction_grid_ion')
        RequestType.create!(
          name: 'Traction GridION',
          key: 'traction_grid_ion',
          request_class_name: 'Request::Traction::GridIon',
          asset_type: 'Well',
          order: 1,
          initial_state: 'pending',
          billable: true,
          request_purpose: :standard
        ) do |rt|
          LibraryTypesRequestType.create!(
            request_type: rt,
            library_type: LibraryType.find_or_create_by!(name: 'Rapid'),
            is_default: true
          )

          LibraryTypesRequestType.create!(
            request_type: rt,
            library_type: LibraryType.find_or_create_by!(name: 'Ligation'),
            is_default: false
          )

          RequestType::Validator.create!(
            request_type: rt,
            request_option: 'library_type',
            valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
          )

          RequestType::Validator.create!(
            request_type: rt,
            request_option: 'data_type',
            valid_options:
              RequestType::Validator::ArrayWithDefault.new(['basecalls', 'basecalls and raw data'], 'basecalls')
          )
        end
      end
    end
  end

  desc 'Create the traction submission templates'
  task create_submission_templates: %i[environment create_request_types] do
    puts 'Creating submission templates....'
    ActiveRecord::Base.transaction do
      unless SubmissionTemplate.exists?(name: 'Traction - GridION')
        SubmissionTemplate.create!(
          name: 'Traction - GridION',
          submission_class_name: 'LinearSubmission',
          product_catalogue: ProductCatalogue.find_by(name: 'Generic'),
          submission_parameters: {
            request_type_ids_list: [RequestType.where(key: 'traction_grid_ion').pluck(:id)]
          }
        )
      end
    end
  end

  desc 'Create the traction purposes'
  task create_purposes: [:environment] do
    puts 'Creating purposes...'
    ActiveRecord::Base.transaction do
      (barcode_printer_type = BarcodePrinterType.find_by(name: '1D Tube')) || raise('Cannot find 1D printer')
      { 'saphyr' => %w[Tube::Purpose SampleTube] }.each do |name, (type, asset_type)|
        type.constantize.create!(name: name, barcode_printer_type: barcode_printer_type, target_type: asset_type)
      end
    end
  end
end
