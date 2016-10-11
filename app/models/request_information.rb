# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class RequestInformation < ActiveRecord::Base
  belongs_to :request_information_type
  belongs_to :request

  scope :information_type, ->(*args) { where(request_information_type_id: args[0]) }
end
