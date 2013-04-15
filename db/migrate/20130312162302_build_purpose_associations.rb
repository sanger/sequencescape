class BuildPurposeAssociations < ActiveRecord::Migration
  def self.up
    IlluminaHtp::PlatePurposes::BRANCHES.each do |branch|
      IlluminaHtp::PlatePurposes.create_branch(branch)
    end
  end

  def self.down
    IlluminaHtp::PlatePurposes::BRANCHES.each do |branch|
      #
    end
  end

end
