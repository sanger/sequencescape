# frozen_string_literal: true

# General purpose flexible search. Can eventually replace a number of existing searches.
# Allows the user to customise the parameters.
class Search::FindPlates < Search
  def scope(user_criteria) # rubocop:todo Metrics/AbcSize
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred
    # (or marked for transfer) the destination plate becomes the end of the chain.
    criteria = default_parameters.stringify_keys.merge(user_criteria)

    # External calls will probably use uuids not ids
    if criteria['plate_purpose_uuids']
      criteria['plate_purpose_ids'] =
        Uuid.where(resource_type: 'Purpose', external_id: criteria['plate_purpose_uuids']).pluck(:resource_id)
    end
    user = criteria['user_uuid'] ? Uuid.lookup_single_uuid(criteria['user_uuid']).resource : nil
    Plate
      .with_purpose(criteria['plate_purpose_ids'])
      .for_user(user)
      .include_labware_with_children(criteria['include_used'])
      .page(criteria['page'])
      .per_page(criteria['limit'])
      .order(id: :desc)
  end
end
