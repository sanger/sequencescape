# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Failure < ActiveRecord::Base
  belongs_to :failable, polymorphic: true
  after_create :notify_remote

  def notify_remote
    if notify_remote?
      # Send event to Studies here
    end
  end
end
