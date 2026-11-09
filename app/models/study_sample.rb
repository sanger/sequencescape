# frozen_string_literal: true
# Links a {Sample} to a {Study}
# @note This association is probably a little unreliable, and should not be relied upon for
# critical behaviour.
class StudySample < ApplicationRecord
  include Api::StudySampleIo::Extensions

  self.per_page = 500
  include Uuid::Uuidable

  belongs_to :study
  belongs_to :sample

  validates :sample_id, uniqueness: { scope: [:study_id], message: 'cannot be added to the same study more than once' }

  broadcast_with_warren
end
