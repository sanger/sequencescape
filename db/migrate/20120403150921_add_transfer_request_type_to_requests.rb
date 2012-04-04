class AddTransferRequestTypeToRequests < ActiveRecord::Migration

  class Requests < ActiveRecord::Base
    belongs_to :request_type
    named_scope :transfer_requests, :conditions => { :sti_type => 'TransferRequest' }
  end

  class RequestType < ActiveRecord::Base
    has_many :requests
  end

  def self.up
    ActiveRecord::Base.transaction do
      transfer_request_type = RequestType.find_by_key('transfer')
      Requests.transfer_requests.each do |request|
        request.request_type = transfer_request_type
        request.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Requests.transfer_requests.each do |request|
        request.request_type = nil
        request.save!
      end
    end
  end
end
