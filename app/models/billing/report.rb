module Billing
  # creates and populates the BIF file
  class Report
    include ActiveModel::Model

    attr_accessor :start_date, :end_date, :file_name, :fields, :billing_items

    validates :start_date, :end_date, :fields, presence: true

    def create
      f = File.new("#{file_name}.bif", 'w+')
      f.write(data)
      f.close
    end

    def data
      ''.tap do |text|
        billing_items.each do |billing_item|
          text << billing_item.to_s(fields)
        end
      end
    end

    def billing_items
      @billing_items ||= Item.created_between(start_date, end_date)
    end

    def file_name
      @file_name ||= 'newfile'
    end

    def start_date=(start_date)
      @start_date = start_date.to_datetime.beginning_of_day if start_date.present?
    end

    def end_date=(end_date)
      @end_date = end_date.to_datetime.end_of_day if end_date.present?
    end
  end
end
