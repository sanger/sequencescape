
class AddGenericProduct < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Product.create!(name: 'Generic')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Product.find_by(name: 'Generic').delete
    end
  end
end
