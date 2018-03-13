# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexDocumentsOnDocumentableIdAndDocumentableType < ActiveRecord::Migration[5.1]
  remove_index :documents_shadow, column: %w[documentable_id documentable_type]
end
