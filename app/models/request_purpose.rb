# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

# A RequestPurpose is a simple means of distinguishing WHY a request was made.
# cf. RequestType which defines how it will be fulfilled.
# Both RequestType and Request have a purpose, with the former acting as the default for
# the latter.
class RequestPurpose < ActiveRecord::Base
  STANDARD_PURPOSE = 'standard'

  validates_presence_of :key
  validates_uniqueness_of :key

  has_many :requests
  has_many :request_types

  def self.standard
    find_by!(key: STANDARD_PURPOSE)
  end
end
