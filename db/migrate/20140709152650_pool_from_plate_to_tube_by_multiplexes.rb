class PoolFromPlateToTubeByMultiplexes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name=>'Transfer wells to MX library tubes by multiplex',
        :transfer_class_name => 'Transfer::FromPlateToTubeByMultiplex'
        )
    end
  end

  def self.down
    ActivRecord::Base.transaction do
       TransferTemplate.find_by_name('Transfer wells to MX library tubes by multiplex').destroy
    end
  end
end
