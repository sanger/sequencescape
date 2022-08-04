# frozen_string_literal: true

# The support action table keeps track of all actions performed
class AddSupportActionTable < ActiveRecord::Migration[6.0]
  def change
    create_table 'support_actions' do |t|
      t.references :user, null: false, foregin_key: true

      t.string 'action', null: false
      t.string 'version', null: false
      t.text 'logs'
      t.json 'urls'
      t.json 'options'

      t.timestamps
    end
  end
end
