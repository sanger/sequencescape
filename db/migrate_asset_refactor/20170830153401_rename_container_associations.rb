# frozen_string_literal: true

# Rename the container associations table to ensure we no longer accidentally use it
class RenameContainerAssociations < ActiveRecord::Migration[4.2]
  def change
    rename_table 'container_associations', 'container_associations_deprecated'
  end
end
