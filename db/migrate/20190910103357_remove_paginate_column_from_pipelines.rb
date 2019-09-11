# frozen_string_literal: true

# The pagination column is false for ALL pipelines. This commit also removes the code
# so we drop the column to avoid future confusion.
class RemovePaginateColumnFromPipelines < ActiveRecord::Migration[5.1]
  def change
    remove_column :pipelines, :paginate, :boolean
  end
end
