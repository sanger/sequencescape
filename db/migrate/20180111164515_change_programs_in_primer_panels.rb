# frozen_string_literal: true

# Programs are serialized hashes, so may be bigger than a varchar
# rubocop:disable Rails/ReversibleMigration
class ChangeProgramsInPrimerPanels < ActiveRecord::Migration[5.1]
  def change
    change_column :primer_panels, :programs, :text
  end
end
# rubocop:enable Rails/ReversibleMigration
