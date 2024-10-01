# frozen_string_literal: true

require_relative 'well_range'

ParameterType(name: 'plate_id', regexp: /the plate with ID (\d+)/, transformer: ->(id) { Plate.find(id) })

ParameterType(
  name: 'asset_id',
  regexp: /the (plate|tube|lane) with ID (\d+)/,
  transformer: ->(_, id) { Labware.find(id) }
)

ParameterType(
  name: 'plate_name',
  regexp: /the plate "([^"]+)"/,
  type: Plate,
  transformer: ->(name) { Plate.find_by!(name:) }
)

ParameterType(
  name: 'asset_name',
  regexp: /the (plate|tube|sample tube|labware) "([^"]+)"/,
  type: Asset,
  transformer: ->(_, name) { Labware.find_by!(name:) }
)

ParameterType(
  name: 'plate_uuid',
  regexp: /the plate with UUID "([\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12})"/,
  type: Plate,
  transformer: ->(uuid) { Uuid.lookup_single_uuid(uuid).resource }
)

ParameterType(
  name: 'uuid',
  regexp: /the (.*) with UUID "([\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12})"/,
  type: ApplicationRecord,
  transformer: ->(_type, uuid) { Uuid.lookup_single_uuid(uuid).resource }
)

ParameterType(
  name: 'submitted_to',
  regexp: /submitted to "([^"]+)"/,
  type: SubmissionTemplate,
  transformer: ->(name) { SubmissionTemplate.find_by!(name:) }
)

ParameterType(
  name: 'well_range',
  regexp: /"?([A-H]\d+)-([A-H]\d+)"?/,
  type: WellRange,
  transformer: ->(start, finish) { WellRange.new(start, finish) }
)

ParameterType(name: 'all_submissions', regexp: /all submissions/, type: Array, transformer: ->(_) { Submission.all })

ParameterType(name: 'direction', regexp: /(to|from)/, type: String, transformer: ->(direction) { direction })

ParameterType(name: 'relationship', regexp: /(parent|child)/, type: String, transformer: ->(direction) { direction })

ParameterType(name: 'batch', regexp: /the last batch/, type: Batch, transformer: ->(_) { Batch.last })

ParameterType(
  name: 'tag_layout_template',
  regexp: /tag layout template "([^"]+)"/,
  type: TagLayoutTemplate,
  transformer: ->(name) { TagLayoutTemplate.find_by!(name:) }
)

ParameterType(
  name: 'tag_layout',
  regexp: /tag layout with ID (\d+)/,
  type: TagLayout,
  transformer: ->(id) { TagLayout.find(id) }
)

ParameterType(
  name: 'study_name',
  regexp: /the study "([^"]+)"/,
  type: Study,
  transformer: ->(name) { Study.find_by!(name:) }
)

ParameterType(
  name: 'asset_creation',
  regexp: /the (plate|tube) creation with ID (\d+)/,
  type: AssetCreation,
  transformer: ->(_, id) { AssetCreation.find(id) }
)

ParameterType(
  name: 'integer_array',
  regexp: /(\d+(?:,\s*\d+)*)/,
  type: Array,
  transformer: ->(int_array) { int_array.split(',').map(&:to_i) }
)

ParameterType(
  name: 'request_class',
  regexp: /(pulldown|illumina-b) library creation/,
  transformer:
    lambda do |name|
      case name
      when 'pulldown'
        Pulldown::Requests::LibraryCreation
      when 'illumina-b'
        IlluminaB::Requests::StdLibraryRequest
      else
        raise StandardError, "Unknown type #{name}"
      end
    end
)

ParameterType(
  name: 'asset_group',
  regexp: /the asset group "([^"]+)"/,
  type: AssetGroup,
  transformer: ->(name) { AssetGroup.find_by!(name:) }
)
