#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddIndicesToContainerAssociations < ActiveRecord::Migration
  def self.up
    # The indices on the container association need repairing
    change_column(:container_associations, :container_id, :integer, :null => false)
    change_column(:container_associations, :content_id, :integer, :null => false)
    remove_index(:container_associations, :column => :content_id)
    add_index(:container_associations, :content_id, :unique => true, :name => 'container_association_content_is_unique')
  end

  def self.down
    # Actually we don't do anything on this because it should be ok to rollback
  end
end
