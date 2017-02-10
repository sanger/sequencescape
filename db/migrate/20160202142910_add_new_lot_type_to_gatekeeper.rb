# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class AddNewLotTypeToGatekeeper < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      pstp = QcablePlatePurpose.create!(name: 'Pre Stamped Tag Plate', target_type: 'Plate', default_state: 'available')
      LotType.create!(name: 'Pre Stamped Tags', template_class: 'TagLayoutTemplate', target_purpose: pstp)
      Purpose::Relationship.create!(parent: Purpose.find_by(name: 'Pre Stamped Tag Plate'), child: Purpose.find_by(name: 'Tag PCR'), transfer_request_type: RequestType.transfer)
    end
  end
end
