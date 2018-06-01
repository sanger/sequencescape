
class StudySample < ApplicationRecord
  include Api::StudySampleIO::Extensions

  self.per_page = 500
  include Uuid::Uuidable

  belongs_to :study
  belongs_to :sample

  validates_uniqueness_of :sample_id, scope: [:study_id], message: 'cannot be added to the same study more than once'

  broadcast_via_warren
end
