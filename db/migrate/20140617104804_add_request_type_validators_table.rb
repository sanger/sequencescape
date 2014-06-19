class AddRequestTypeValidatorsTable < ActiveRecord::Migration
  def self.up
    create_table(:request_type_validators) do |t|
      t.references :request_type,   :null => false
      t.string     :request_option, :null => false
      t.text       :valid_options,  :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :request_type_validators
  end
end
