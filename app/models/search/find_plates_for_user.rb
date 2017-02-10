# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

class Search::FindPlatesForUser < Search
  def scope(user_criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    criteria = default_parameters.stringify_keys.merge(user_criteria)

    # External calls will probably use uuids not ids
    criteria['plate_purpose_ids'] = Uuid.where(resource_type: 'Purpose', external_id: criteria['plate_purpose_uuids']).pluck(:id) if criteria['plate_purpose_uuids']

    Plate.with_plate_purpose(criteria['plate_purpose_ids'])
      .for_user(Uuid.lookup_single_uuid(criteria['user_uuid']).resource)
      .including_used_plates?(criteria['include_used'])
      .page(criteria['page']).limit(criteria['limit']).order('plate_owners.id DESC')
  end
end
