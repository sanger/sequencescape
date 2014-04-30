class AddSpecificTubeTransfers < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name => 'Transfer between specific tubes',
        :transfer_class_name => 'Transfer::BetweenSpecificTubes'
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name('Transfer between specific tubes').destroy
    end
  end

end
