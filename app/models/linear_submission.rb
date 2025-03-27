# frozen_string_literal: true
# this class it simplified version of Submission which is just a chain of request types
# without any choices
class LinearSubmission < Order
  include Submission::LinearRequestGraph

  def request_type_ids=(id_list)
    self.request_type_ids_list = id_list.zip
  end

  def request_type_ids
    request_type_ids_list.map(&:first)
  end
end
