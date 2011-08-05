class HideNonSequencescapePipelines < ActiveRecord::Migration
  def self.up
    add_column :pipelines, :externally_managed, :boolean, :default => false

    ::Pipeline.reset_column_information
    ::Pipeline.update_all('externally_managed=TRUE', [ 'name IN (?)', [ 'Pulldown WGS', 'Pulldown SC', 'Pulldown ISC' ] ])
  end

  def self.down
    remove_column :pipelines, :externally_managed
  end
end
