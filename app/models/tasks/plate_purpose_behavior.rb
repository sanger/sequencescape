module Tasks
  module PlatePurposeBehavior # rubocop:todo Style/Documentation
    # Returns a list of valid plate purpose types based on the requests in the current batch.
    def plate_purpose_options(batch) # rubocop:todo Metrics/AbcSize
      requests = batch.requests.flat_map(&:next_requests)
      plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
      plate_purposes = PlatePurpose.cherrypickable_as_target.all if plate_purposes.empty? # Fallback situation for the moment
      plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
    end
  end
end
