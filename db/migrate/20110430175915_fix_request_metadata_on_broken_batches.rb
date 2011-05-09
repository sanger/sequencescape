class FixRequestMetadataOnBrokenBatches < ActiveRecord::Migration
  REQUEST_OPTIONS = [ :fragment_size_required_from, :fragment_size_required_to, :library_type ]

  NonUniqueOptionsError = Class.new(StandardError)

  def self.up
    ActiveRecord::Base.transaction do
      done, tried, failed = 0, 0, 0
      Batch.find_in_batches(:include => { :pipeline => :request_type, :requests => :request_metadata }) do |batches|
        say_with_time("Doing batches #{done}-#{done+batches.size} ...") do
          batches.each do |batch|
            # Some of our batches contain requests that appear to have disappeared!
            if batch.requests.any?(&:blank?)
              say("Batch #{batch.id} has requests that have since been deleted")
            elsif batch.valid?
              # Ignore valid batches, we're only interested in the broken ones
            else
              begin
                # All request options should be identical across all of the requests in a batch.  If they are not, or they
                # are all nil, then this batch cannot be fixed automatically (and is probably old).
                request_options = batch.requests.inject(Hash.new { |h,k| h[k] = Set.new }) do |options, request|
                  options.tap do |options|
                    REQUEST_OPTIONS.each { |f| options[f].add(request.request_metadata[f]) }
                  end
                end
                REQUEST_OPTIONS.each { |f| request_options[f] = request_options[f].to_a.compact }
                raise NonUniqueOptionsError, "Batch #{batch.id} has non-unique request options: #{request_options.inspect}" if request_options.values.any? { |o| o.size > 1 }

                # Now that we have the unique options we can assign them to any of the requests that are invalid.  Any
                # requests that fail to update are invalid for other reasons.  We can also switch the actual request
                # implementation class at the same time.
                request_type = batch.pipeline.request_type
                batch.requests.each do |request|
                  next if request.valid?
                  request = request.becomes(request_type.request_class)
                  request.sti_type = request_type.request_class_name
                  REQUEST_OPTIONS.each { |f| request.request_metadata[f] = request_options[f].first }
                  request.save!
                end
              rescue NonUniqueOptionsError => exception
                say(exception.message)
                failed += 1
              rescue ActiveRecord::RecordInvalid => exception
                # There's something very wrong with the request we just tried to update!
                say("Cannot update requests in batch #{batch.id}: #{exception.record.errors.full_messages.inspect}")
                failed += 1
              ensure
                tried += 1
              end
            end
          end

          done += batches.size
        end
      end

      say("Tried #{tried} and failed #{failed}") unless failed.zero?
    end
  end

  def self.down
  end
end
