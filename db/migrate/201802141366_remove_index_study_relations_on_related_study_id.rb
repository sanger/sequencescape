# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexStudyRelationsOnRelatedStudyId < ActiveRecord::Migration[5.1]
  remove_index :study_relations, column: ['related_study_id']
end
