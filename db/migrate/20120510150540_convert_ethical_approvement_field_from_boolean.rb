class Study < ActiveRecord::Base

  has_one(:study_metadata, { :class_name => 'Study::Metadata', :foreign_key => "study_id" } )

  named_scope :approval_required,
    :joins => ', study_metadata',
    :conditions => [
      'study_metadata.contaminated_human_dna = ? AND study_metadata.contains_human_dna = ? AND study_metadata.commercially_available = ?',
      'No', 'Yes', 'No']
  named_scope :no_approval_required,
    :joins => ', study_metadata',
    :conditions => [
      'study_metadata.contaminated_human_dna != ? OR study_metadata.contains_human_dna != ? OR study_metadata.commercially_available != ?',
      'No', 'Yes', 'No']

  class Metadata < ActiveRecord::Base
  end
end

class ConvertEthicalApprovementFieldFromBoolean < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      change_column :studies, :ethically_approved, :string, :default => 'No'
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      change_column :studies, :ethically_approved, :boolean, :default => false
    end
  end
end
