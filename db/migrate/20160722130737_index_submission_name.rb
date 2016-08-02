class IndexSubmissionName < ActiveRecord::Migration
  def change
    add_index :submissions, :name
  end
end
