class AddX10LibraryCreationPooling < ActiveRecord::Migration
  def self.transfer_layout_96
    layout = {}
    ('A'..'H').each do |row|
      (1..12).each do |column|
        layout["#{row}#{column}"]="#{row}1"
      end
    end
    layout
  end

  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name => "Pooling rows to first column",
        :transfer_class_name => "Transfer::BetweenPlates",
        :transfers => self.transfer_layout_96
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name!("Pooling rows to first column").destroy
    end
  end
end
