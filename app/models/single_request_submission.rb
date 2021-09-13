# frozen_string_literal: true
class SingleRequestSubmission < Order # rubocop:todo Style/Documentation
  def request_type_id=(request_type_id)
    request_type_ids_list = [[request_type_id]]
  end

  def request_type_id
    request_type_ids_list.first.first
  end
end
