class CreateFlippedTemplate < ActiveRecord::Migration
  def self.up
    TransferTemplate.create!(
      :name => 'Flip Plate',
      :transfer_class_name => 'Transfer::BetweenPlates',
      :transfers => template
    )
  end

  def self.down
    TransferTemplate.find_by_name('Flip Plate').destroy
  end

  def self.template
    wells = (1..12).map {|c| ('A'..'H').map {|r| "#{r}#{c}"}}.flatten
    Hash[wells.zip(wells.reverse)]
  end
end
