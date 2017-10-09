# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015,2016 Genome Research Ltd.

class RequestInformationType < ApplicationRecord
  has_many :pipeline_request_information_types
  has_many :pipelines, through: :pipeline_request_information_types

  scope :shown_in_inbox, ->() { where(hide_in_inbox: false) }
end
