class ExtendSizeTransferTemplatesTransfersColumn < ActiveRecord::Migration[6.0]
  def change
    change_column :transfer_templates, :transfers, :string, :limit => 10240
  end
end
