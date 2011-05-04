class FixControlRequestTypeInBatches < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      done = 0
      Batch.find_in_batches(:include => [ { :pipeline => :request_type }, { :requests => :asset } ]) do |batches|
        say_with_time("Doing batches #{done}-#{done+batches.size} ...") do
          batches.each do |batch|
            # Some of our batches contain requests that appear to have disappeared!
            if batch.requests.any?(&:blank?)
              say("Batch #{batch.id} has requests that have since been deleted")
            else
              batch.control.tap do |control|
                next if control.blank?

                begin
                  # The control requests are of the Request class and must have the RequestType of the pipeline
                  control = control.becomes(Request)
                  control.sti_type        = 'Request'
                  control.request_type_id = batch.pipeline.request_type_id
                  control.save!
                rescue ActiveRecord::RecordInvalid => exception
                  say("Batch #{batch.id} has control #{control.id} which is invalid: #{exception.record.errors.full_messages.inspect}")
                end
              end
            end
          end
        end

        done += batches.size
      end
    end
  end

  def self.down
    # Nothing to do here, data fix
  end
end
