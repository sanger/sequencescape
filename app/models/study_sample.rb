class StudySample < ActiveRecord::Base
  include Api::StudySampleIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  belongs_to :study
  belongs_to :sample


  validates_uniqueness_of :sample_id, :scope => [:study_id], :message => "cannot be added to the same study more than once"
end
