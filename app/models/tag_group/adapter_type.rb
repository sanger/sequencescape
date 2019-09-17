# frozen_string_literal: true

# AdapterType is a property of a {TagGroup} which determines how the tag sequence
# interacts with the Sequencing process. It is recorded in Sequencescape as it
# can affect which processes a tag group is suitable for, and thus can be used
# to filter lists of validate selections.
class TagGroup::AdapterType < ApplicationRecord
  UNSPECIFIED = 'Unspecified'

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validate :name_is_not_reserved
  # Prevent destruction on in-use adapter types
  has_many :tag_groups, dependent: :restrict_with_error

  def name_is_not_reserved
    return unless UNSPECIFIED.casecmp?(name)

    errors.add(:name, "cannot be '#{UNSPECIFIED}' as this is reserved.")
  end
end
