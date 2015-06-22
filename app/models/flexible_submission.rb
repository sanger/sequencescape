#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
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
    return nil if request_types.blank?
    mxr = RequestType.find(:all,:conditions=>{:id=>request_types,:for_multiplexing=>true}).each do |mx_request|
      yield(request_types[request_types.index(mx_request.id)+1].to_s.to_sym)
    end
    yield(request_types.first.to_s.to_sym) if mxr.empty?
    nil
  end

end
