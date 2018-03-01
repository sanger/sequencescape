# frozen_string_literal: true

#
# Stores a record of which templates have been used in which submission
# This ensures that a tag clash is not introduced prior to later pooling.
# We can also enforce uniqueness at the database level, eliminating race
# conditions when multiple plates get processed at the same time. This
# is a genuine risk, as the users often process multiple plates in parallel
# and processing time is non-trivial.
#
# A note on future changes:
# Once we've solved the duplicate-tag-sequences problems it might make
# sense to actually track tag sequence pairs here, but hopefully by that
# point we'll be pooling flexibly anyway. We'd probably also still need
# to be able to show which templates had been used, as a huge list of
# oligo sequences isn't very user friendly.
#
# @author Genome Research Ltd.
#
class TagLayout::TemplateSubmission < ApplicationRecord
  belongs_to :submission, required: true
  belongs_to :tag_layout_template, required: true

  # @!attribute [rw] enforce_uniqueness
  #   @return [nil, true] true to enforce uniqueness of a template within a submission
  #                       or nil to allow duplicate templates. This is enforced at the database level

  validates :tag_layout_template, uniqueness: { scope: :submission }, if: :enforce_uniqueness?
  validates :enforce_uniqueness, inclusion: { in: [true, nil] }

  before_validation :coerce_false_enforce_uniqueness_to_nil

  # By setting the value to nil, we can bypass the uniqueness constraint
  # on the database.
  def coerce_false_enforce_uniqueness_to_nil
    self.enforce_uniqueness = nil if enforce_uniqueness == false
  end
end
