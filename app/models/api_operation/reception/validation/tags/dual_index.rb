# frozen_string_literal: true

# Tags given as a dual index tag set and a well in it, which gives the tag and
# tag 2. Mirrors the sample manifest's dual_index_tag_set and
# dual_index_tag_well fields.
class ApiOperation::Reception::Validation::Tags::DualIndex <
      ApiOperation::Reception::Validation::Tags::Scheme
  # The payload fields of this scheme
  FIELDS = %w[dual_index_tag_set dual_index_tag_well].freeze

  # How this scheme is named in messages
  NAME = 'dual index tag set and well'
end
