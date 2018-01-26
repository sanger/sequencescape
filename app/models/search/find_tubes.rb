# frozen_string_literal: true

class Search::FindTubes < Search
  def scope(user_criteria)
    criteria = default_parameters.stringify_keys.merge(user_criteria)

    purpose_ids = if criteria['tube_purpose_uuids']
                    Uuid.where(resource_type: 'Purpose', external_id: criteria['tube_purpose_uuids'])
                        .pluck(:resource_id)
                  else
                    criteria['tube_purpose_ids']
                  end

    Tube.with_purpose(purpose_ids)
        .including_used_plates?(criteria['include_used'])
        .page(criteria['page']).limit(criteria['limit']).order(id: :desc)
  end
end
