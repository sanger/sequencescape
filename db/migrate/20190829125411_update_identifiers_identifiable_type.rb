# frozen_string_literal: true

# Ensure events point at the appropriate class
class UpdateIdentifiersIdentifiableType < ActiveRecord::Migration[5.1]
  def up
    Identifier.where(external_type: 'Snp::DnaWell').update_all(identifiable_type: 'Receptacle')
    Identifier.where(external_type: 'Snp::DnaPlate').update_all(identifiable_type: 'Labware')
  end

  def down
    # We can't roll back once new events have been created
    raise ActiveRecord::IrreversibleMigration
  end
end
