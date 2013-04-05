class AddOrderIdDataToRequests < ActiveRecord::Migration

  class Request < ActiveRecord::Base
    belongs_to :submission
    belongs_to :order

  end

  def self.up
    Request.find_in_batches(:include=>{:submission=>:orders}, :conditions => ['submission_id IS NOT NULL AND order_id IS NULL']) do |batch|
      ActiveRecord::Base.transaction do
        say "Processing requests #{batch.first.id} to #{batch.last.id}"
        batch.each do |request|
          next if request.submission.nil?
          if request.submission.orders.count == 1
            request.update_attributes!(:order=>request.submission.orders.first)
          end
        end
      end
    end
  end

  def self.down
    Request.find_in_batches(:conditions => ['order_id IS NOT NULL']) do |batch|
      ActiveRecord::Base.transaction do
        say "Processing requests #{batch.first.id} to #{batch.last.id}"
        batch.each do |request|
          request.update_attributes!(:order=>nil)
        end
      end
    end
  end
end
