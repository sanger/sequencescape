class IncreaseLengthOfTagLayoutSubstitutions < ActiveRecord::Migration
  def self.up
    change_column 'tag_layouts', 'substitutions', :string, :limit => 1525
  end

  def self.down
    change_column 'tag_layouts', 'substitutions', :string, :limit => 255
  end
end
