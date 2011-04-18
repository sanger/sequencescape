class StudySample < ActiveRecord::Base
  belongs_to :study
  belongs_to :sample
  acts_as_audited :on => [:destroy, :update]

  validates_uniqueness_of :sample_id, :scope => [:study_id], :message => "cannot be added to the same study more than once" 
  
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  named_scope :including_associations_for_json, { :include => [:uuid_object, {:study => :uuid_object }, {:sample => :uuid_object } ] }
  
  def self.render_class
    Api::StudySampleIO
  end
  
end
