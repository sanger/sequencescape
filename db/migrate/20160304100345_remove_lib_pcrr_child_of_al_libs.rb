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
