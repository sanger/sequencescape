class AddCherrypickableSourcePlatePurposes < ActiveRecord::Migration
  SOURCE_PLATE_TYPES = [
    ["ABgene_0765", false],
    ["ABgene_0800", true],
    ["FluidX075", false]
  ]

  def self.up
    ActiveRecord::Base.transaction do
      SOURCE_PLATE_TYPES.each do |name, target|
        PlatePurpose.create!(:name => name, :can_be_considered_a_stock_plate => false, :cherrypickable_source => true, :cherrypickable_target => target)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SOURCE_PLATE_TYPES.each do |name, _|
        PlatePurpose.find_by_name(name).destroy
      end
    end
  end
end
