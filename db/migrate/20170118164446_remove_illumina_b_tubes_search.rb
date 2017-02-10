class RemoveIlluminaBTubesSearch < ActiveRecord::Migration
  class Search < ActiveRecord::Base
    self.table_name = 'searches'
    self.inheritance_column = nil
  end
  def up
    Search.find_by(name: 'Find Illumina-B tubes').try(:destroy)
  end

  def down
    Search.create!(name: 'Find Illumina-B tubes', type: 'Search::FindIlluminaBTubes')
  end
end
