# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

##
# FlexibleSubmissions allow multiplexing based on
# pooling properties defined on the multiplexed request type
class FlexibleSubmission < Order
  include Submission::FlexibleRequestGraph::OrderMethods
  include Submission::Crossable

  def request_type_ids=(id_list)
    self.request_type_ids_list = id_list.map { |i| [i] }
  end

  def request_type_ids
    request_type_ids_list.map(&:first)
  end

  def request_type_multiplier(&block)
    return nil if request_types.blank?
    found_some = false
    # Unfortunately we don't seem to be able to use the return value
    # of find_each to discover if it found something
    RequestType.where(id: request_types, for_multiplexing: true).find_each do |mx_request|
      found_some = true
      yield(request_types[request_types.index(mx_request.id) + 1].to_s.to_sym)
    end
    yield(request_types.first.to_s.to_sym) unless found_some
    nil
  end
end
