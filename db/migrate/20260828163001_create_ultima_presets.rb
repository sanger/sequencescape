# frozen_string_literal: true

# See https://cdn.sanity.io/files/l7780ks7/production-2024/9777db79cbb0379b5962bf51c94b05bcc741c841.pdf
class CreateUltimaConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :ultima_configurations,
                 comment: 'Sample sheet configurations for Ultima applications' do |t|
      t.string :application_type,
               null: false,
               comment: 'Application type used in the Samples section, e.g. scRNA_GEX_10x_flex'
      t.string :application_preset,
               null: false,
               comment: 'Application preset used in the Global section, e.g. 10x Flex'
      t.string :sequencing_recipe,
               null: false,
               comment: 'Sequencing recipe used to select the highest preset for mixed types, e.g. 75 cycles'

      t.timestamps
    end
  end
end
