# frozen_string_literal: true

# Run the rake task with the following command:
# bundle exec rake number_of_samples_per_pool:populate[20,1]
# The rake task will populate the number of samples per pool column in the request_metadata table
# for a given submission ID.
namespace :number_of_samples_per_pool do
  desc 'Populate number of samples per pool column in request_metadata table for a given submission ID'

  task :populate, %i[samples_per_pool submission_id] => :environment do |_, args|
    args.with_defaults(samples_per_pool: nil, submission_id: nil)

    raise StandardError, 'Number of samples per pool is missing' if args[:samples_per_pool].nil?
    raise StandardError, 'Submission ID is missing' if args[:submission_id].nil?

    puts "Populating number of samples per pool column with #{args[:samples_per_pool]}
        in request_metadata table for submission: #{args[:submission_id]}..."

    ActiveRecord::Base.transaction do
      saved_count = 0
      Request::Metadata
        .joins(:request)
        .where(requests: { submission_id: args[:submission_id] })
        .find_each(batch_size: 50) do |request_metadata|
          puts "Processing request_metadata #{request_metadata.id}..."
          saved_count = process_request_metadata(request_metadata, saved_count, args[:samples_per_pool])
        end
    end
  end

  def process_request_metadata(request_metadata, saved_count, samples_per_pool)
    request_metadata.number_of_samples_per_pool = samples_per_pool
    begin
      request_metadata.save!
      saved_count += 1
    rescue ActiveRecord::ActiveRecordError, StandardError => e
      puts "Error processing request_metadata #{request_metadata.id}: #{e.message}"
      raise e
    end
    saved_count
  end
end
