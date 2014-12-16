class AddLibraryStripPrefix < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      BarcodePrefix.create!(:prefix=>'LS')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      BarcodPrefix.find_by_prefix('LS').destroy
    end
  end
end
