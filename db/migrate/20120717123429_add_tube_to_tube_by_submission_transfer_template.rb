class AddTubeToTubeBySubmissionTransferTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name                => "Transfer from tube to tube by submission",
        :transfer_class_name => Transfer::BetweenTubesBySubmission.name
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name("Transfer from tube to tube by submission").destroy
    end
  end
end
