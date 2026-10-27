# frozen_string_literal: true

# Checks the payload's labware before anything is created, and collects every
# problem, each with a pointer into the payload:
# - Each barcode appears once in the payload.
# - A new tube has one receptacle, with no position.
# - A new plate's positions are wells of its size, each listed once.
# - Each sample in the new labware has an existing study. An unknown study is
#   reported once, at the first sample that uses it, with how many do.
# Known labware is checked by ApiOperation::Reception::Reconciliation instead,
# and its samples are not stored, so they aren't checked here.
class ApiOperation::Reception::Validation
  # @param payload_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] all the payload's labware
  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  def initialize(payload_labware, new_labware)
    @payload_labware = payload_labware
    @new_labware = new_labware
  end

  # @return [Array<Hash>] the problems, each with a :pointer and a :detail
  def errors
    @errors ||=
      duplicate_barcode_errors +
      @new_labware.flat_map { |labware| receptacle_errors(labware) } +
      study_errors
  end

  private

  # An error for each study UUID that isn't a Sequencescape study
  def study_errors
    samples_by_study = new_samples.group_by(&:study_uuid)
    return [] if samples_by_study.empty?

    known = Study.with_uuid(samples_by_study.keys).pluck('uuids.external_id')
    samples_by_study.except(*known).map do |uuid, samples|
      error("#{samples.first.pointer}/study_uuid",
            "No study with UUID #{uuid} (used by " \
            "#{samples.size} #{'sample'.pluralize(samples.size)})")
    end
  end

  def new_samples
    @new_labware.flat_map(&:receptacles).flat_map(&:samples)
  end

  # An error for each labware after the first with the same barcode
  def duplicate_barcode_errors
    @payload_labware.group_by(&:barcode).values.select(&:many?)
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

  def error(pointer, detail)
    { pointer:, detail: }
  end
end
