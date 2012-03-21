class RenameIlluminaCLibraryPrepPipeline < ActiveRecord::Migration
  def self.up
    Pipeline.find_by_name('Library preparation').update_attributes(:name=> 'Illumina-C Library preparation')
  end

  def self.down
    Pipeline.find_by_name('Illumina-C Library preparation').update_attributes(:name=> 'Library preparation')
  end
end
