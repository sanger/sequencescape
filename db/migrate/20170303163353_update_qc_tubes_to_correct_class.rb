# Rails migration
class UpdateQcTubesToCorrectClass < ActiveRecord::Migration
  PURPOSE_OLD_TARGET = {
    'PF MiSeq Stock' => 'StockMultiplexedLibraryTube',
    'PF MiSeq QC' => 'MultiplexedLibraryTube',
    'PF MiSeq QCR' => 'MultiplexedLibraryTube'
  }

  def up
    ActiveRecord::Base.transaction do
      purposes = Purpose.where(name: PURPOSE_OLD_TARGET.keys)
      Asset.where(plate_purpose_id: purposes).update_all(sti_type: 'QcTube')
    end
  end

  def down
    ActiveRecord::Base.transaction do
      PURPOSE_OLD_TARGET.each do |name, target|
        purpose = Purpose.find_by(name: name)
        Asset.where(plate_purpose_id: purpose).update_all(sti_type: target)
      end
    end
  end
end
