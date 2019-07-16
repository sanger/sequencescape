# Submissions can be found by name, so we index it to improve performance
class IndexSubmissionName < ActiveRecord::Migration
  def change
    add_index :submissions, :name
  end
end
