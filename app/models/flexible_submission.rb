require 'submission/flexible_request_graph'
##
# FlexibleSubmissions allow multiplexing based on
# pooling properties defined on the multiplexed request type
class FlexibleSubmission < Order
  include Submission::FlexibleRequestGraph::OrderMethods

  def request_type_ids=(id_list)
    self.request_type_ids_list = id_list.map {|i| [i] }
  end

  def request_type_ids
    request_type_ids_list.map(&:first)
  end

end
