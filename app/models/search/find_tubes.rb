# frozen_string_literal: true

class Search::FindTubes < Search # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/MethodLength
  def scope(user_criteria) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    criteria = default_parameters.stringify_keys.merge(user_criteria)

    purpose_ids =
      if criteria['tube_purpose_uuids']
        Uuid.where(resource_type: 'Purpose', external_id: criteria['tube_purpose_uuids']).pluck(:resource_id)
      else
        criteria['tube_purpose_ids']
      end

    Tube
      .with_purpose(purpose_ids)
      .include_labware_with_children(criteria['include_used'])
      .includes(:transfer_requests_as_target, aliquots: Io::Aliquot::PRELOADS)
      .page(criteria['page'])
      .limit(criteria['limit'])
      .order(id: :desc)
  end
  # rubocop:enable Metrics/MethodLength
end
