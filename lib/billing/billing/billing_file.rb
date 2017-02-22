module Billing
  class BillingFile
    include ActiveModel::Model

    attr_accessor :month, :file_name

    def create
      name = file_name || 'newfile'
      f = File.new("#{name}.bif", 'w+')
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
      all_requests = Request.joins(:request_events).where('request_events.current_from' => period, 'request_events.event_name' => 'state_changed', 'request_events.to_state' => 'passed').group_by { |request| request.sti_type }
      seq_requests = all_requests['HiSeqSequencingRequest'] + all_requests['MiSeqSequencingRequest']
    end

    def period
      m = month || Time.current.month
      Date.new(Time.current.year, m).beginning_of_day..Date.new(Time.current.year, m, -1).end_of_day
    end
  end
end
