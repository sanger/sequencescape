module Billing
  class BillingFile

    def create
      f = File.new("newfile.biff",  "w+")
      f.write(data)
      f.close
    end

    def data
      [].tap do |text|
        seq_requests.each do |request|
          lines = BillingData.new(request: request).lines
          text << lines
        end
      end.join('')
    end

    def seq_requests
      period = Date.new(2017, 2, 1).beginning_of_day..Time.now
      all_requests = Request.joins(:request_events).where('request_events.current_from' => period, 'request_events.event_name' => 'state_changed', 'request_events.to_state' => 'passed').group_by {|request| request.sti_type }
      seq_requests = all_requests["HiSeqSequencingRequest"] + all_requests["MiSeqSequencingRequest"]
    end

  end
end