# frozen_string_literal: true
##
# FlexibleSubmissions allow multiplexing based on
# pooling properties defined on the multiplexed request type
class FlexibleSubmission < Order
  include Submission::FlexibleRequestGraph::OrderMethods
  include Submission::Crossable

  def request_type_ids=(id_list)
    self.request_type_ids_list = id_list.zip
  end

  def request_type_ids
    request_type_ids_list.map(&:first)
  end

  def request_type_multiplier # rubocop:todo Metrics/AbcSize
    return nil if request_types.blank?

    mxr = RequestType.where(id: request_types, for_multiplexing: true)
    mxr.find_each { |mx_request| yield(request_types[request_types.index(mx_request.id) + 1].to_s.to_sym) }
    yield(request_types.first.to_s.to_sym) if mxr.empty?
    nil
  end
end
