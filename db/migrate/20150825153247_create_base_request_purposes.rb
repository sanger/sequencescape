# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class CreateBaseRequestPurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestPurpose.create!(key: 'standard')
      RequestPurpose.create!(key: 'qc')
      RequestPurpose.create!(key: 'internal')
      RequestPurpose.create!(key: 'control')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestPurpose.find_by!(key: 'standard').destroy
      RequestPurpose.find_by!(key: 'qc').destroy
      RequestPurpose.find_by!(key: 'internal').destroy
      RequestPurpose.find_by!(key: 'control').destroy
    end
  end
end
