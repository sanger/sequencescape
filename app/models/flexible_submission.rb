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

  def request_type_multiplier(&block)
    RequestType.find(:all,:conditions=>{:id=>request_types,:for_multiplexing=>true}).each do |mx_request|
      yield(request_types[request_types.index(mx_request.id)+1].to_s.to_sym)
    end unless request_types.blank?
    nil
  end

end
