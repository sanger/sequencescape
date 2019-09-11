# If we change a target, we may need to re-broadcast its messenger, so lets
# add an index.
class AddIndexToMessengers < ActiveRecord::Migration[5.1]
  def change
    add_index :messengers, %i[target_id target_type]
  end
end
