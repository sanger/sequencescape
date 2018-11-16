
namespace :long_read do
  desc 'Create the long read request types'
  task create_request_type: [:environment] do
    puts 'Creating request types...'
    ActiveRecord::Base.transaction do
      unless RequestType.where(key: 'long_read').exists?
        RequestType.create!(
          name: 'Long Read',
          key: 'long_read',
          request_class_name: 'Request::LongRead',
          asset_type: 'Well',
          order: 1,
          initial_state: 'pending',
          billable: true,
          request_purpose: :standard
        ) do |rt|
          LibraryTypesRequestType.create!(request_type: rt, library_type: LibraryType.find_or_create_by!(name: 'Long Read'), is_default: true)

          RequestType::Validator.create!(
            request_type: rt,
            request_option: 'library_type',
            valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
          )
        end
      end
    end
  end

  desc 'Create the long read submission templates'
  task create_submission_template: %i(environment create_request_type) do
    puts 'Creating submission templates....'
    ActiveRecord::Base.transaction do
      unless SubmissionTemplate.where(name: 'Long Read').exists?
        SubmissionTemplate.create!(
          name: 'Long Read',
          submission_class_name: 'LinearSubmission',
          product_catalogue: ProductCatalogue.find_by(name: 'Generic'),
          submission_parameters: {
            request_type_ids_list: [RequestType.where(key: 'long_read').pluck(:id)]
          }
        )
      end
    end
  end
end
