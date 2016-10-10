#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011 Genome Research Ltd.
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
