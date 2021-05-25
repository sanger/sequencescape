# frozen_string_literal: true

# Ensure barcodes points at labware, not assets
class UpdateCommentCommentableTypes < ActiveRecord::Migration[5.1]
  def up
    Comment
      .where(commentable_type: 'Asset')
      .joins('INNER JOIN receptacles ON receptacles.id = commentable_id')
      .update_all(commentable_type: 'Receptacle')
    Comment
      .where(commentable_type: 'Asset')
      .joins('INNER JOIN  labware ON labware.id = commentable_id')
      .update_all(commentable_type: 'Labware')
  end

  def down
    # As soon as even a single asset or receptacle has been created
    # we can't rollback.
    raise ActiveRecord::IrreversibleMigration
  end
end
