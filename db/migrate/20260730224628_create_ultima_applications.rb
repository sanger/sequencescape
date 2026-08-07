# frozen_string_literal: true

class CreateUltimaApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :ultima_applications,
                 comment: 'Ultima application configurations for sample sheets' do |t|
      t.string :application_preset, null: false, comment: 'Global Application, e.g. Converted TruSeq'
      t.string :application_type, null: false, comment: 'Sample application_type, e.g. converted-truseq'
      t.string :sequencing_recipe, null: false, comment: 'Sequencing cycles, e.g. 116cycles'

      t.timestamps
    end
  end
end
