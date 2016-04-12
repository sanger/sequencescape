#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.
module RequestClassDeprecator

  class Request < ActiveRecord::Base
    self.table_name = 'requests'
  end

  def transfer_request
    RequestType.find_by_key!('transfer')
  end

  def deprecate_class(request_class_name)

    ActiveRecord::Base.transaction do
      RequestType.where(request_class_name:request_class_name).each do |rt|
        say "Deprecating: #{rt.name}"
        rt.update_attributes!(deprecated: true)
        Request.where(request_type_id:rt.id,sti_type:request_class_name).update_all(sti_type:'TransferRequest',request_type_id:transfer_request.id)
        PlatePurpose::Relationship.where(transfer_request_type_id:rt.id).update_all(transfer_request_type_id:rt.id)
      end
    end
  end

end
