# frozen_string_literal: true

# Assigns the plate purpose to the plates of a work order's
# requested_labware_identifiers (see config/schemas/work-order-schema).
#
# The purpose depends on the submission template, as mapped in
# config/sapio_work_order/plate_purpose_mapping_by_submission.yml. The template
# name may carry a sequencing platform suffix ("<mapped name> - <platform>"),
# so the longest mapped name the template name starts with is used.
#
# Only plates whose current purpose is 'Library Stock Plate' are given a mapped
# purpose; other plates, and tubes, are left alone.
class ApiOperation::WorkOrder::PlatePurposeResolver
  STOCK_PURPOSE_NAME = 'Library Stock Plate'
  POINTER = '/work_order/requested_labware_identifiers'
  CONFIG_PATH = Rails.root.join('config/sapio_work_order/plate_purpose_mapping_by_submission.yml')

  # @return [Hash{String => Array<String>}] plate purpose names by submission template name
  def self.mapping
    @mapping ||= YAML.safe_load_file(CONFIG_PATH).freeze
  end

  # @param work_order [Hash] the payload's parsed work_order section
  # @param template [SubmissionTemplate] the template the work order is submitted with
  # @param requested_receptacles [ApiOperation::WorkOrder::RequestedReceptacles, nil] the
  #   work order's requested receptacles, found from its identifiers if not given
  def initialize(work_order, template, requested_receptacles: nil)
    @requested_receptacles = requested_receptacles ||
      ApiOperation::WorkOrder::RequestedReceptacles.new(work_order['requested_labware_identifiers'])
    @template = template
  end

  # Identifiers that name no usable receptacle are skipped; validation reports them.
  # @return [Array<Plate>] the Library Stock Plates given the purpose
  # @raise [ApiOperation::Error] if the template has no single mapped purpose,
  #   or the purpose doesn't exist
  def assign!
    return [] if stock_plates.empty?

    purpose = plate_purpose
    return [] if purpose.nil?

    stock_plates.each { |plate| plate.update!(plate_purpose: purpose) }
  end

  # @return [Array<Plate>] the distinct plates the identifiers name
  delegate :plates, to: :@requested_receptacles

  # @return [Array<Plate>] those of the plates whose purpose is 'Library Stock Plate'
  def stock_plates
    @stock_plates ||= plates.select { |plate| plate.plate_purpose&.name == STOCK_PURPOSE_NAME }
  end

  # @return [PlatePurpose, nil] nil if the template has no mapping
  def plate_purpose
    names = mapped_names
    return if names.nil?

    unless names.one?
      raise ApiOperation::Error.new(POINTER, "Cannot determine a single plate purpose for '#{@template.name}'")
    end

    PlatePurpose.find_by(name: names.first) ||
      raise(ApiOperation::Error.new(POINTER, "Cannot find plate purpose #{names.first.inspect}"))
  end

  private

  def mapped_names
    key = self.class.mapping.keys.select { |name| @template.name.start_with?(name) }.max_by(&:length)
    self.class.mapping[key] if key
  end
end
