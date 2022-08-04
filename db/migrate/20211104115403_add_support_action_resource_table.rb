# frozen_string_literal: true

# Join an action to any affected resources
class AddSupportActionResourceTable < ActiveRecord::Migration[6.0]
  def change
    create_table 'support_actions_resources' do |t|
      # Need to supply custom index names as the ones rails generates are too long
      t.references :support_action, null: false, foregin_key: true, index: { name: 'idx_support_action' }
      t.references :resource, null: false, polymorphic: true, index: { name: 'idx_support_resources' }
      t.timestamps
    end
  end
end
