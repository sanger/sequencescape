# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module RequestsHelper #:nodoc: all
  def request_status(request)
    state = request.state.blank? ? 'unknown' : request.state
    content_tag(:span, state.upcase, class: "request-state text-#{bootstrapify(state.downcase)}")
  end

  def read_length(request)
    if request.descriptor_value_for_key('read_length')
      "(#{request.descriptor_value_for_key("read_length").value} cycles)"
    end
  end
end
