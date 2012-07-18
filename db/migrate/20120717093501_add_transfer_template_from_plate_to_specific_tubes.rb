class AddTransferTemplateFromPlateToSpecificTubes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name                => "Transfer wells to specific tubes by submission",
        :transfer_class_name => Transfer::FromPlateToSpecificTubes.name
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name('Transfer wells to specific tubes by submission').destroy
    end
  end
end
