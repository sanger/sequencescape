class AddPcrCyclesToRequestMetadata < ActiveRecord::Migration
  def change
    change_table 'request_metadata' do |t|
      t.column 'pcr_cycles', :integer, null: true
    end
  end
end
