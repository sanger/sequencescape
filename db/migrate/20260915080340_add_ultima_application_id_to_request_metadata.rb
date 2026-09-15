# frozen_string_literal: true
class AddUltimaApplicationIdToRequestMetadata < ActiveRecord::Migration[8.1]
  def change
    add_column :request_metadata, :ultima_application_id, :integer
  end
end
