class AddUserSearches < ActiveRecord::Migration
  def self.up
    {
 'Find user by login' => Search::FindUserByLogin,
     'Find user by swipecard code' => Search::FindUserBySwipecardCode
    }.each do |name, model|
      model.create!(:name => name) unless model.find_by_name(name)
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
