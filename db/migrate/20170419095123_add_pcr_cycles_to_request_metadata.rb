# Rails migration
class AddPcrCyclesToRequestMetadata < ActiveRecord::Migration
  def change
    add_column 'request_metadata', 'pcr_cycles', :integer, null: true
  end
end
