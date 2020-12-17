# Pre Stamped stamp plates represent plates that come in ready stamped and pre-quality controlled
class AddNewLotTypeToGatekeeper < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      pstp = QcablePlatePurpose.create!(name: 'Pre Stamped Tag Plate', target_type: 'Plate', default_state: 'available')
      LotType.create!(name: 'Pre Stamped Tags', template_class: 'TagLayoutTemplate', target_purpose: pstp)
      Purpose::Relationship.create!(parent: Purpose.find_by(name: 'Pre Stamped Tag Plate'),
                                    child: Purpose.find_by(name: 'Tag PCR'), transfer_request_type: RequestType.transfer)
    end
  end
end
