class AddPoolingMethodIdToRequestTypes < ActiveRecord::Migration
  def self.up
    add_column :request_types, :pooling_method_id, :integer
  end

  def self.down
    remove_column :request_types, :pooling_method_id
  end
end
