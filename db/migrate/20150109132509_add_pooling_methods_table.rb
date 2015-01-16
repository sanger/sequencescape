class AddPoolingMethodsTable < ActiveRecord::Migration
  def self.up
    create_table :pooling_methods do |t|
      t.string   "pooling_behaviour",        :limit => 50, :null => false
      t.text     "pooling_options"
    end

  end

  def self.down
    drop_table :pooling_methods
  end
end
