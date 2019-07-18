# Avoid the need to create lots of search classes for minor parameter variations
class AddParametersToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :default_parameters, :text
  end
end
