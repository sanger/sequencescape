# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Event::SampleManifestEvent < Event
  def self.created_sample!(sample, user)
    create!(
      eventful: sample,
      message: 'Created by Sample Manifest',
      content: Date.today.to_s,
      family: 'created_sample_using_sample_manifest',
      created_by: user ? user.login : nil
    )
  end

  def self.updated_sample!(sample, user)
    create!(
      eventful: sample,
      message: 'Updated by Sample Manifest',
      content: Date.today.to_s,
      family: 'updated_sample_using_sample_manifest',
      created_by: user ? user.login : nil
    )
  end
end
