#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddTransferRequestTypeToRequests < ActiveRecord::Migration

  class Requests < ActiveRecord::Base
    belongs_to :request_type
    scope :transfer_requests, -> { where( :sti_type => 'TransferRequest' ) }
  end

  class RequestType < ActiveRecord::Base
    has_many :requests
  end

  def self.up
    ActiveRecord::Base.transaction do
      transfer_request_type = RequestType.find_by_key('transfer').id
      Requests.update_all({:request_type_id => transfer_request_type}, ["sti_type = ?",'TransferRequest'])
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Requests.update_all({:request_type_id => nil}, ["sti_type = ?",'TransferRequest'])
    end
  end
end
