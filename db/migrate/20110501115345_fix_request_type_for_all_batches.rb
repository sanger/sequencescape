class FixRequestTypeForAllBatches < ActiveRecord::Migration
  EMPTY_OR_UNIQUE = [0,1]

  def self.up
    ActiveRecord::Base.transaction do
      count = 0

      # Cannot eager load the requests as this causes an error during validation
      Batch.find_in_batches(:include => :pipeline) do |batches|
        say_with_time("Doing batches #{count}-#{count+batches.size}") do
          batches.each do |batch|
            next if batch.valid?
            next unless Array(batch.errors.on(:requests)).include?('has incorrect type')

            # Determine if we have a unique set of request type IDs, as we can't pick if there are multiple
            # choices.  We also can't deal with cases where the unique request type isn't the same as the
            # pipeline.
            request_type_ids = batch.requests.map(&:request_type_id).compact.uniq
            if request_type_ids.empty? or ([ batch.pipeline.request_type_id ] == request_type_ids)
              begin
                batch.requests.each { |r| r.update_attributes!(:request_type_id => request_type_ids.first) }
              rescue ActiveRecord::RecordInvalid => exception
                say("Batch #{batch.id} has requests that fail validation")
              end
            else
              say("Batch #{batch.id} cannot be fixed: requests say #{request_type_ids.inspect} but pipeline is #{batch.pipeline.request_type_id}")
            end
          end
        end

        count += batches.size
      end
    end
  end

  def self.down
  end
end
