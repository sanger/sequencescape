class AddToSpecificTubesByPoolTransferTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name => 'Transfer wells to specific tubes defined by submission',
        :transfer_class_name => 'Transfer::FromPlateToSpecificTubesByPool'
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name('Transfer wells to specific tubes defined by submission').destroy
    end
  end
end
