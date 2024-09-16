# frozen_string_literal: true
namespace :number_of_samples_per_pool do

  desc 'Populate number of samples per pool column in request_metadata table'

  task :populate, %i[samples_per_pool submission_id] => :environment do |_, args|

    # TODO: Replace it with the pre-determined number of samples per pool
    args.with_defaults(samples_per_pool: 96)

    if args[:submission_id].nil?
      puts 'Please provide a submission_id to populate the number of samples per pool column.'
      return
    end

    puts "Populating number of samples per pool column with #{args[:samples_per_pool]} in request_metadata
        table for submission: #{args[:submission_id]}..."

    ActiveRecord::Base.transaction do
      saved_count = 0
      request_metadatas = Request::Metadata.where(number_of_samples_per_pool: nil, submission_id: args[:submission_id])
      # Assuming there are multiple requests for a submission
      request_metadatas.find_each(batch_size: 50) do |request_metadata|
        puts "Processing request_metadata #{request_metadata.id}..."
        saved_count = process_request_metadata(request_metadata, saved_count)
      end
      puts "Populated number of samples per pool column for #{saved_count} request_metadata items."
    end
  end

  def process_request_metadata(request_metadata, saved_count)
    request_metadata.number_of_samples_per_pool = 96
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