# frozen_string_literal: true

# Tags given as a Chromium tag group and a well in it, whose four tags the
# sample gets. Mirrors the sample manifest's chromium_tag_group and
# chromium_tag_well fields.
class ApiOperation::Reception::Validation::Tags::Chromium <
      ApiOperation::Reception::Validation::Tags::Scheme
  # The payload fields of this scheme
  FIELDS = %w[chromium_tag_group chromium_tag_well].freeze

  # How this scheme is named in messages
  NAME = 'Chromium tag group and well'
end
