# frozen_string_literal: true

class CreateUltimaApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :ultima_applications,
                 comment: 'Relationship between applications, primers, and instruments' do |t|
      t.string :name,
               null: false,
               comment: 'Name used in UI and bulk submissions, e.g. 10x Flex'
      t.text :description,
             null: false,
             comment: 'Description of the application, e.g. 10x Genomics GEM-X Flex Gene Expression'

      t.references :ug100_configuration,
                   null: false,
                   comment: 'Application preset, type, and recipe used for UG100',
                   foreign_key: {
                     to_table: :ultima_configurations,
                     name: :fk_ultima_apps_on_ug100_config
                   }
      t.references :ug200_configuration,
                   null: false,
                   comment: 'Application preset, type, and recipe used for UG200',
                   foreign_key: {
                     to_table: :ultima_configurations,
                     name: :fk_ultima_apps_on_ug200_config
                   }
      t.references :uga_primer,
                   null: false,
                   comment: 'UGA indexing primer (Forward/R1 side)',
                   foreign_key: {
                     to_table: :ultima_primers,
                     name: :fk_ultima_apps_on_uga_primer
                   }
      t.references :ugb_primer,
                   null: false,
                   comment: 'UGB primer (Reverse/R2 side)',
                   foreign_key: {
                     to_table: :ultima_primers,
                     name: :fk_ultima_apps_on_ugb_primer
                   }

      t.timestamps
    end
  end
end
