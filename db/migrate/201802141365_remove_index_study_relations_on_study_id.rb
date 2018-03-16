# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexStudyRelationsOnStudyId < ActiveRecord::Migration[5.1]
  remove_index :study_relations, column: ['study_id']
end
