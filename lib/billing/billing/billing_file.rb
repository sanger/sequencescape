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
      String.new.tap do |text|
        seq_requests.find_each do |request|
          lines = BillingData.new(request: request).lines
          text << lines
        end
      end
    end

    def seq_requests
      SequencingRequest.joins(:request_events)
        .where(request_events: { current_from: period, event_name: 'state_changed', to_state: 'passed' })
        .joins(:request_type)
        .where(request_types: { billable: true })
        .includes(asset: :aliquots)
    end

    def period
      m = month || Time.current.month
      Date.new(Time.current.year, m).beginning_of_day..Date.new(Time.current.year, m, -1).end_of_day
    end
  end
end
