# frozen_string_literal: true

# Tags given as a tag group and the tag's index in it, for the tag (tag_group,
# tag_index) and for tag 2 (tag2_group, tag2_index). Mirrors the sample
# manifest's tag_group, tag_index, tag2_group and tag2_index fields.
class ApiOperation::Reception::Validation::Tags::TagGroups <
      ApiOperation::Reception::Validation::Tags::Scheme
  # The payload fields of this scheme
  FIELDS = %w[tag_group tag_index tag2_group tag2_index].freeze

  # How this scheme is named in messages
  NAME = 'tag group and index'
end
