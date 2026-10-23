# frozen_string_literal: true

# This task corrects stale acceptable-purpose associations for the Fluidigm cherrypick pipeline.
# Run once per environment after deployment.
namespace :single_use do
  desc 'Fix acceptable purposes for the Fluidigm cherrypick request types'
  task fix_fluidigm_acceptable_purposes: [:environment] do
    expected_purpose_names = {
      'pick_to_snp_type' => 'STA2',
      'pick_to_fluidigm' => 'SNP Type'
    }
    allowed_purpose_names = ['STA2', 'SNP Type']

    request_types_and_purposes = expected_purpose_names.map do |key, purpose_name|
      request_type = RequestType.find_by!(key:)
      expected_purpose = Purpose.find_by!(name: purpose_name)
      [request_type, expected_purpose, request_type.acceptable_purposes.to_a]
    end

    request_types_and_purposes.each do |request_type, _expected_purpose, purposes|
      purpose_names = purposes.map(&:name)
      puts "Before #{request_type.key}: #{purpose_names.inspect}"

      unexpected_purposes = purpose_names - allowed_purpose_names
      next if unexpected_purposes.empty?

      raise "Unexpected acceptable purposes for #{request_type.key}: " \
            "#{unexpected_purposes.inspect}. Aborting without making changes."
    end

    ActiveRecord::Base.transaction do
      request_types_and_purposes.each do |request_type, expected_purpose, current|
        next if current.map(&:id) == [expected_purpose.id]

        request_type.acceptable_purposes = [expected_purpose]
      end
    end

    request_types_and_purposes.each do |request_type, _expected_purpose, _current|
      puts "After #{request_type.key}: " \
           "#{request_type.reload.acceptable_purposes.pluck(:name).inspect}"
    end
  end
end
