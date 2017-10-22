# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class RemoveLibPcrrChildOfAlLibs < ActiveRecord::Migration
  def child_to_remove
    Purpose.find_by(name: 'Lib PCRR').id
  end

  def parent_to_detach
    Purpose.find_by(name: 'AL Libs').id
  end

  def up
    ActiveRecord::Base.transaction do
      PlatePurpose::Relationship.where(
        parent_id: parent_to_detach,
        child_id: child_to_remove
      ).first.destroy
    end
  end

  def down
    ActiveRecord::Base.transaction do
      PlatePurpose::Relationship.create!(
        parent_id: parent_to_detach,
        child_id: child_to_remove,
        transfer_request_type: RequestType.find_by(key: 'Illumina_AL_Libs_Lib_PCRR')
      )
    end
  end
end
