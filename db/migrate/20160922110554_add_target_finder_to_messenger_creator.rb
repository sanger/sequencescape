# Rails migration
# Used by Cherrypicking to decide to generate fluidigm messengers
class AddTargetFinderToMessengerCreator < ActiveRecord::Migration
  def change
    add_column :messenger_creators, :target_finder_class, :string, null: false, default: 'SelfFinder'
  end
end
