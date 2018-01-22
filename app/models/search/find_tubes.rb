# frozen_string_literal: true

class Search::FindTubes < Search
  def scope(user_criteria)
    criteria = default_parameters.stringify_keys.merge(user_criteria)

    if criteria['plate_purpose_uuids']
      criteria['plate_purpose_ids'] = Uuid.where(resource_type: 'Purpose', external_id: criteria['plate_purpose_uuids'])
                                          .pluck(:resource_id)
    end

    Tube.with_purpose(criteria['plate_purpose_ids'])
        .including_used_plates?(criteria['include_used'])
        .page(criteria['page']).limit(criteria['limit']).order(id: :desc)
  end
end
