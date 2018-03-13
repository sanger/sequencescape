# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

# General purpose flexible search. Can eventually replace a number of existing searches.
# Allows the user to customise the parameters.
class Search::FindPlates < Search
  def scope(user_criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    criteria = default_parameters.stringify_keys.merge(user_criteria)

    # External calls will probably use uuids not ids
    criteria['plate_purpose_ids'] = Uuid.where(resource_type: 'Purpose', external_id: criteria['plate_purpose_uuids']).pluck(:resource_id) if criteria['plate_purpose_uuids']
    user = criteria['user_uuid'] ? Uuid.lookup_single_uuid(criteria['user_uuid']).resource : nil
    Plate.with_plate_purpose(criteria['plate_purpose_ids'])
         .for_user(user)
         .include_plates_with_children(criteria['include_used'])
         .page(criteria['page']).per_page(criteria['limit']).order(id: :desc)
  end
end
