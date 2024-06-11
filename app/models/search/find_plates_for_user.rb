# frozen_string_literal: true
class Search::FindPlatesForUser < Search
  def scope(user_criteria) # rubocop:todo Metrics/AbcSize
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred
    # (or marked for transfer) the destination plate becomes the end of the chain.
    criteria = default_parameters.stringify_keys.merge(user_criteria)

    # External calls will probably use uuids not ids
    if criteria['plate_purpose_uuids']
      criteria['plate_purpose_ids'] =
        Uuid.where(resource_type: 'Purpose', external_id: criteria['plate_purpose_uuids']).pluck(:id)
    end

    Plate
      .with_purpose(criteria['plate_purpose_ids'])
      .for_user(Uuid.lookup_single_uuid(criteria['user_uuid']).resource)
      .include_labware_with_children(criteria['include_used'])
      .page(criteria['page'])
      .limit(criteria['limit'])
      .order('plate_owners.id DESC')
  end
end
