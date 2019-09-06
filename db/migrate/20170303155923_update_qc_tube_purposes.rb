# Rails migration
class UpdateQcTubePurposes < ActiveRecord::Migration
  PURPOSE_OLD_TARGET = {
    'PF MiSeq Stock' => 'StockMultiplexedLibraryTube',
    'PF MiSeq QC' => 'MultiplexedLibraryTube',
    'PF MiSeq QCR' => 'MultiplexedLibraryTube'
  }.freeze

  def up
    ActiveRecord::Base.transaction do
      Purpose.where(name: PURPOSE_OLD_TARGET.keys).update_all(target_type: 'QcTube')
    end
  end

  def down
    ActiveRecord::Base.transaction do
      PURPOSE_OLD_TARGET.each do |name, target|
        purpose = Purpose.find_by(name: name)
        purpose.target_type = target
        purpose.save!
      end
    end
  end
end
