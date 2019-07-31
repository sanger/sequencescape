# Rails migration
class CreateSampleWorkOrder < ActiveRecord::Migration[5.1]
  def change
    create_table :sample_work_orders do |t|
      t.belongs_to :sample, index: true
      t.belongs_to :work_order, index: true
      t.timestamps
    end
  end
end
