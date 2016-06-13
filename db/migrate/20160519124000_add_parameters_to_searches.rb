class AddParametersToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :default_parameters, :text
  end
end
