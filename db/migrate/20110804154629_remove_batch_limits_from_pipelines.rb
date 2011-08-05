class RemoveBatchLimitsFromPipelines < ActiveRecord::Migration
  def self.up
    Pipeline.update_all('max_size=8', 'name LIKE "%Cluster formation%"')
  end

  def self.down
    Pipeline.update_all('max_size=NULL', 'name LIKE "%Cluster formation%"')
  end
end
