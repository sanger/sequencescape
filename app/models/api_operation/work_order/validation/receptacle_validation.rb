# frozen_string_literal: true

# Checks one of a work order's requested labware identifiers: the labware and
# receptacle it names must exist, and the receptacle must hold something.
#
# An identifier is a tube barcode ("TUBE-Y"), or a plate barcode and a well
# position separated by a colon ("PLATE-X:A1").
class ApiOperation::WorkOrder::Validation::ReceptacleValidation
  POINTER = '/work_order/requested_labware_identifiers'

  # @return [String] the requested labware identifier, stripped
  attr_reader :identifier

  # @param identifier [String] the requested labware identifier
  # @param pointer [String] the JSON pointer errors report, by default the
  #   requested labware identifiers
  def initialize(identifier, pointer: POINTER)
    @identifier = identifier.to_s.strip
    @barcode, @position = @identifier.split(':', 2).map(&:strip)
    @pointer = pointer
  end

  # @return [Array<ApiOperation::Error>] the problem; empty if
  #   the identifier names an existing receptacle that isn't empty
  def errors
    @errors ||= problem ? [ApiOperation::Error.new(@pointer, problem)] : []
  end

  def valid?
    errors.empty?
  end

  # @return [Receptacle, nil] the well or tube receptacle the identifier names
  def receptacle
    return @receptacle if defined?(@receptacle)

    @receptacle = @position ? well : labware&.receptacles&.first
  end

  private

  def problem
    if labware.nil?
      "Cannot find labware with barcode #{@barcode.inspect}"
    elsif @position.nil? && labware.receptacles.many?
      "#{@barcode} has several receptacles; specify a well as #{@barcode}:A1"
    elsif receptacle.nil?
      "Cannot find well #{@position.inspect} on #{@barcode}"
    elsif receptacle.empty?
      "#{@identifier} is empty"
    end
  end

  def labware
    return @labware if defined?(@labware)

    @labware = @barcode.present? ? Labware.find_by_barcode(@barcode) : nil
  end

  def well
    labware.try(:wells)&.located_at(@position)&.first
  end
end
