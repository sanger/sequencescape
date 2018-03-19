# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexRequestInformationsOnRequestId < ActiveRecord::Migration[5.1]
  remove_index :request_informations, column: ['request_id']
end
