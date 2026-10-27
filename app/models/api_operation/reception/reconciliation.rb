# frozen_string_literal: true

# Sorts the payload's labware into labware Sequencescape already has, which
# is matched and left unchanged (ADR 074), and new labware, which reception
# creates. A payload labware is known if its barcode is any of a
# Sequencescape labware's barcodes, even if nothing else about it matches.
class ApiOperation::Reception::Reconciliation
  # @param payload_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload's labware
  def initialize(payload_labware)
    @payload_labware = payload_labware
  end

  # @return [Hash{PayloadLabware => Labware}] the payload labware that
  #   Sequencescape already has, with its Sequencescape labware
  def matched
    @matched ||=
      @payload_labware.each_with_object({}) do |payload_labware, matched|
        labware = find_labware(payload_labware)
        matched[payload_labware] = labware if labware
      end
  end

  # @return [Array<PayloadLabware>] the payload labware that Sequencescape
  #   doesn't have, in payload order
  def new_labware
    @payload_labware - matched.keys
  end

  private

  # The Sequencescape labware with the payload labware's barcode, in any of
  # the forms it may be stored in, if there is one.
  def find_labware(payload_labware)
    Barcode.extract_barcode(payload_labware.barcode)
      .lazy.filter_map { |barcode| labware_by_barcode[barcode] }.first
  end

  # The Sequencescape labware with any of the payload's barcodes, found in
  # one query, by each of its barcodes.
  def labware_by_barcode
    @labware_by_barcode ||=
      ::Labware.with_barcode(*@payload_labware.map(&:barcode))
        .preload(:barcodes)
        .each_with_object({}) do |labware, index|
          labware.barcodes.each { |barcode| index[barcode.barcode] = labware }
        end
  end
end
