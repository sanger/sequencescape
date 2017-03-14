# We'll try and do this through the API with the live version

namespace :limber do
  desc 'Create the limber request types'
  task create_request_types: :environment do
    ActiveRecord::Base.transaction do
      rt = RequestType.create!(
        name: 'Limber PWGS',
        key: 'limber_pwgs',
        request_class_name: 'IlluminaHtp::Requests::StdLibraryRequest',
        for_multiplexing: false,
        workflow: Submission::Workflow.find_by(name: 'Next-gen sequencing'),
        asset_type: 'Well',
        order: 1,
        initial_state: 'pending',
        billable: true,
        product_line: ProductLine.find_by(name: 'Illumina-Htp'),
        request_purpose: RequestPurpose.standard
      ) do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by(name: 'LB Cherrypick')
        rt.library_types = LibraryType.where(name: ['Standard'])
      end

      RequestType::Validator.create!(
        request_type: rt,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )

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
        request_purpose: RequestPurpose.standard,
        target_purpose: Purpose.find_by(name: 'LB Lib Pool Norm')
      )
    end
  end

  task create_submission_templates: :environment do
    ActiveRecord::Base.transaction do
      Limber::Helper::TemplateConstructor.new(
        name: 'PWGS',
        role: 'PWGS',
        type: 'limber_pwgs',
        catalogue: ProductCatalogue.find_by!(name: 'PWGS')
      ).build!
    end
  end
end
