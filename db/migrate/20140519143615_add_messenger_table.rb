class AddMessengerTable < ActiveRecord::Migration
  def self.up
    create_table 'messengers' do |t|
      t.references :target, :polymorphic => true
      t.string 'root', :null=>false
      t.string 'template', :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table 'messengers'
  end
end
