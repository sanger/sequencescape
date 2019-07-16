# frozen_string_literal: true

# Ensure events point at the appropriate class
class UpdateIdentifiersIdentifiableTypes < ActiveRecord::Migration[5.1]
  def up
    Lot.where(template_type: 'Asset').update_all(template_type: 'Labware')
  end

  def down
    # We can't roll back once new events have been created
    raise ActiveRecord::IrreversibleMigration
  end
end
