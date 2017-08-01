module Billing
  # creates and populates the BIF file
  class Report
    include ActiveModel::Model

    attr_accessor :start_date, :end_date, :file_name, :fields

    def create(file_name = 'newfile')
      f = File.new("#{file_name}.bif", 'w+')
      billing_items = find_billing_items(start_date, end_date)
      f.write(data(billing_items))
      f.close
    end

    def data(billing_items)
      ''.tap do |text|
        billing_items.each do |billing_item|
          text << billing_item.to_s(fields)
        end
      end
    end

    def find_billing_items(start_date, end_date)
      Item.created_between(start_date, end_date)
    end

    def start_date=(start_date)
      @start_date = start_date.to_datetime.beginning_of_day if start_date.present?
    end

    def end_date=(end_date)
      @end_date = end_date.to_datetime.end_of_day if end_date.present?
    end
  end
end
