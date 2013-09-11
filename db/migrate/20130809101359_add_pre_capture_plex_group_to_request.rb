class AddPreCapturePlexGroupToRequest < ActiveRecord::Migration
  def self.up

    create_table :pre_capture_pool_pooled_requests do |t|
      t.references  :pre_capture_pool, :null => false
      t.references  :request, :null => false
    end

    add_index :pre_capture_pool_pooled_requests, [:request_id], :name => "request_id_should_be_unique", :unique => true

  end

  def self.down
    drop_table :pre_capture_pool_pooled_requests
  end
end
