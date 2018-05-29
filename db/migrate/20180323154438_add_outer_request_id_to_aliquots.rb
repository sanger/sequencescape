# frozen_string_literal: true

# Avoid walking down the entire request graph by providing a shortcut
# Using an older version to ensure we use the right column type
class AddOuterRequestIdToAliquots < ActiveRecord::Migration[4.2]
  def change
    add_reference :aliquots, :request, foreign_key: true
  end
end
