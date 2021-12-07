# frozen_string_literal: true
module Tasks
  module PlatePurposeBehavior # rubocop:todo Style/Documentation
    # Returns a list of valid plate purpose types based on the requests in the current batch.
    def plate_purpose_options(batch)
      requests = batch.requests.flat_map(&:next_requests)
      plate_purposes = requests.filter_map(&:request_type).uniq.map(&:acceptable_purposes).flatten.uniq

      # Fallback situation for the moment
      plate_purposes = PlatePurpose.cherrypickable_as_target.all if plate_purposes.empty?
      plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
    end
  end
end
