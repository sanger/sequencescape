# frozen_string_literal: true

class CreateUltimaPrimers < ActiveRecord::Migration[8.1]
  def change
    create_table :ultima_primers,
                 comment: 'UGA/UGB primers used for Ultima applications' do |t|
      t.string :name,
               null: false,
               comment: 'Name of the UGA or UGB primer, e.g. UG-tR1, UG-tR2'

      t.timestamps
    end
  end
end
