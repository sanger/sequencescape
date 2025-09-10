# frozen_string_literal: true

#
# A polymetadatum is a key value pair store. It is set up such that it can be
# associated with multiple different models (ie. a polymorphic relationship).
#
# It can be linked to any model that has the reverse association set up.
# i.e. add this association line to the model:
# has_many :poly_metadata, as: :metadatable, dependent: :destroy
# and this line to the v2 api resource (if api access needed):
# has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'
#
# See Request model and associated api v2 resource for an example of how to use this.
#
class PolyMetadatum < ApplicationRecord
  # Associations
  belongs_to :metadatable, polymorphic: true, optional: false

  include Api::Messages::CommentIo::PolyMetadatumBatchAliquots

  # Validations
  validates :key, presence: true # otherwise nil is a valid key
  validates :value, presence: true

  # Currently we allow the same key to be used for different metadatable objects,
  # but it has to be unique for each metadatable object and is case insensitive.
  # This is to allow the same key to be used for different models, e.g. a request
  # and a sample might both have metadata called 'somename', but the same model cannot
  # have two metadata called 'somename' and 'SOMENAME'.
  # A metadatable has both a type and an id, so the combination key is unique.
  # metadatable_type is the class name of the model, e.g. 'Request'
  # metadatable_id is the database id of the model instance
  validates :key, uniqueness: { scope: %i[metadatable_type metadatable_id], case_sensitive: false }

  after_commit :broadcast_under_rep_batch_aliquot

  # Methods
  def to_h
    { key => value }
  end

  def related_batches
    return [] unless metadatable_type == 'Request'

    metadatable.submission.batches
  end

  def broadcast_under_rep_batch_aliquot
    return unless key == 'under_represented' && related_batches.any?

    Messenger.create!(target: self, template: 'CommentIo', root: 'comment').broadcast
  end
end
