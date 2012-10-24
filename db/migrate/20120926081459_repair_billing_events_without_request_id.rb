# Ensures all billing events have a request_id
class RepairBillingEventsWithoutRequestId < ActiveRecord::Migration

  class BillingEvent < ActiveRecord::Base

    def self.do_not_record_timestamps(&block)
      BillingEvent.record_timestamps = false
      yield
    ensure
      BillingEvent.record_timestamps = true
    end

  end

  def self.up
    ActiveRecord::Base.transaction do
      BillingEvent.do_not_record_timestamps do

        BillingEvent.find_all_by_request_id(nil).each do |billing_event|
          request_match = /RT*([0-9]*)/.match(billing_event.reference)

          raise "#{billing_event.reference} is in unexpected reference format and has not been repaired. Aborting." if request_match.nil?

          request_id = request_match[1]
          say "Repairing #{billing_event.id}:#{billing_event.reference} => #{request_id}"
          billing_event.update_attributes!(:request_id => request_id)
        end

      end
    end
  end

  def self.down

  end
end
