# frozen_string_literal: true

# Checks the payload's labware:
# - Each barcode appears once in the payload, known labware included.
# - New labware is of a type reception can create (not UNSUPPORTED_TYPES).
# - A new tube has one receptacle, with no position.
# - A new plate's positions are wells of its size, each listed once.
class ApiOperation::Reception::Validation::LabwareCheck <
      ApiOperation::Reception::Validation::Check
  # Labware types reception can't create yet, as no purpose is decided for
  # them, with how they are named in messages. Known labware of these types
  # can still be matched.
  UNSUPPORTED_TYPES = { 'plate384' => '384-well plates' }.freeze

  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    @errors ||=
      duplicate_barcode_errors +
      input.new_labware.flat_map do |labware|
        unsupported_type_errors(labware).presence || receptacle_errors(labware)
      end
  end

  private

  # An error if reception can't create labware of this type; its receptacles
  # aren't checked then
  def unsupported_type_errors(payload_labware)
    name = UNSUPPORTED_TYPES[payload_labware.type]
    return [] unless name

    [error("#{payload_labware.pointer}/type",
           "#{name} are not supported by reception yet")]
  end

  # An error for each labware after the first with the same barcode
  def duplicate_barcode_errors
    input.payload_labware.group_by(&:barcode).values.select(&:many?)
      .flat_map do |same_barcode|
        first, *others = same_barcode
        others.map do |payload_labware|
          error("#{payload_labware.pointer}/barcode",
                "Barcode #{payload_labware.barcode} is also used by " \
                "#{first.pointer}")
        end
      end
  end

  def receptacle_errors(payload_labware)
    size = plate_size(payload_labware)
    size ? well_errors(payload_labware, size) : tube_errors(payload_labware)
  end

  def tube_errors(payload_labware)
    receptacles = payload_labware.receptacles
    unless receptacles.one?
      return [error("#{payload_labware.pointer}/receptacles",
                    "A tube has one receptacle, not #{receptacles.size}")]
    end
    return [] if receptacles.sole.position.nil?

    [error("#{receptacles.sole.pointer}/position",
           "A tube's receptacle has no position")]
  end

  def well_errors(payload_labware, size)
    seen = Set.new
    payload_labware.receptacles.filter_map do |receptacle|
      detail = position_problem(receptacle.position, size, seen)
      error("#{receptacle.pointer}/position", detail) if detail
    end
  end

  # What is wrong with a well's position, if anything. Adds a good position
  # to seen, so a second listing of it is a problem.
  def position_problem(position, size, seen)
    if position.nil?
      'A well needs a position'
    elsif well_descriptions(size).exclude?(position)
      "#{position} is not a well of a #{size}-well plate"
    elsif !seen.add?(position)
      "Well #{position} is listed more than once"
    end
  end

  # @return [Integer, nil] the plate's size, or nil for a tube
  def plate_size(payload_labware)
    ApiOperation::Reception::Reconciliation::TYPES
      .fetch(payload_labware.type).last
  end

  # The wells of a standard plate of the size
  def well_descriptions(size)
    @well_descriptions ||= Hash.new do |descriptions, plate_size|
      descriptions[plate_size] =
        Map.where_plate_size(plate_size)
          .where_plate_shape(AssetShape.default_id).pluck(:description).to_set
    end
    @well_descriptions[size]
  end
end
