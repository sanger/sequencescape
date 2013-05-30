class WholePlateToTubeTransferTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name => 'Whole plate to tube',
        :transfer_class_name => 'Transfer::FromPlateToTube',
        :transfers => plate_map
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name('Whole plate to tube').destroy
    end
  end

  def self.plate_map
    {}.tap {|a| ('A'..'H').each {|l| (1..12).each {|n| a["#{l}#{n}"]="#{l}#{n}" }}}
  end
end
