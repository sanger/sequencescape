# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

# Use in migrations to degrecate request classes
# Usage:
# include RequestClassDeprecator
# deprecate_class('ClassName',options)
# options an otional hash
# {
# new_type: The new request type for affected requests. 'transfer' by default
# state_change: Hash of from_state => to_state applied to affected requests
# }
module RequestClassDeprecator
  class Request < ActiveRecord::Base
    self.table_name = 'requests'
  end

  def transfer_request
    RequestType.find_by!(key: 'transfer')
  end

  def deprecate_class(request_class_name, options = {})
    state_changes = options.fetch(:state_change, {})
    new_request_type = options.fetch(:new_type, transfer_request)
    new_class_name = new_request_type.request_class_name

    ActiveRecord::Base.transaction do
      RequestType.where(request_class_name: request_class_name).each do |rt|
        say "Deprecating: #{rt.name}"
        rt.update_attributes!(deprecated: true)

        rt_requests = Request.where(request_type_id: rt.id, sti_type: request_class_name)

        state_changes.each do |from_state, to_state|
          say "Moving #{rt.name} from #{from_state} to #{to_state}", true
          mig = rt_requests.where(state: from_state).update_all(state: to_state)
          say "Moved: #{mig}", true
        end

        say 'Updating requests:'
        mig = rt_requests.update_all(sti_type: new_class_name, request_type_id: new_request_type.id)
        say "Updated: #{mig}", true
        PlatePurpose::Relationship.where(transfer_request_type_id: rt.id).update_all(transfer_request_type_id: new_request_type.id)
      end
    end
  end
end
