# frozen_string_literal: true
#
# Migration to extend the size of the transfers column
class ExtendSizeTransferTemplatesTransfersColumn < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up { change_column :transfer_templates, :transfers, :string, limit: 10_240 }
      dir.down { change_column :transfer_templates, :transfers, :string, limit: 1024 }
    end
  end
end
