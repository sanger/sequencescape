module Tasks
  module PlatePurposeBehavior
    # Returns a list of valid plate purpose types based on the requests in the current batch.
    def plate_purpose_options(batch)
      requests       = batch.requests.map { |r| r.submission ? r.submission.next_requests(r) : [] }.flatten
      plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
      plate_purposes = PlatePurpose.cherrypickable_as_target.all if plate_purposes.empty?  # Fallback situation for the moment
      plate_purposes.map { |p| [p.name, p.id] }.sort
    end
  end
end
