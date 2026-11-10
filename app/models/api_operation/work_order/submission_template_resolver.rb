# frozen_string_literal: true

# Resolves the SubmissionTemplate for a reception_and_work_order operation.
#
# Reads the service name, sequencing platform, requested labware identifiers
# and options from the operation's work_order payload (see
# config/schemas/work-order-schema), maps the Sapio service name to a
# library prep template name using config/sapio_submission_templates.yml, and
# finds that template. If the request has a sequencing platform, its wording
# is appended: "<configured name> - <platform wording>".
class ApiOperation::WorkOrder::SubmissionTemplateResolver
  include ActiveModel::Validations

  POINTER = '/work_order/service_name'
  CONFIG_PATH = Rails.root.join('config/sapio_work_order/sapio_submission_templates.yml')

  # Sapio sequencing_platform values, as they appear in submission template names.
  PLATFORM_KEYWORDS = {
    'Aviti' => 'Element Aviti sequencing',
    'MiSeq' => 'MiSeq sequencing',
    'NovaSeq6000' => 'NovaSeq 6000 Paired end sequencing',
    'NovaSeqX' => 'NovaSeqX paired end sequencing',
    'UG100' => 'Ultima UG100 sequencing',
    'UG200' => 'Ultima UG200 sequencing'
  }.freeze

  attr_reader :service_name, :sequencing_platform

  validates :service_name, presence: true

  # @return [Hash{String => Array<String>}] template names by Sapio service name
  def self.mapping
    @mapping ||= YAML.safe_load_file(CONFIG_PATH).fetch('services').freeze
  end

  # @param api_operation [ApiOperation] an operation whose payload is JSON text
  # @raise [JSON::ParserError] if the payload is not valid JSON
  def initialize(api_operation)
    work_order = JSON.parse(api_operation.payload)['work_order'] || {}
    @service_name = work_order['service_name']
    @sequencing_platform = work_order['sequencing_platform']
  end

  # @return [SubmissionTemplate]
  # @raise [ActiveModel::ValidationError] if service_name is missing
  # @raise [ApiOperation::Error] if the service is not mapped, or unless the service has exactly one configured name
  # @raise [StandardError] if the template is missing or deprecated (from BulkSubmission#find_template)
  def submission_template
    validate!
    BulkSubmission.new.find_template(template_name)
  end

  private

  def template_name
    base_name = configured_name
    platform_keyword.present? ? "#{base_name} - #{platform_keyword}" : base_name
  end

  # The platform as worded in template names, e.g. 'NovaSeq6000' => 'NovaSeq 6000 Paired end sequencing'.
  def platform_keyword
    PLATFORM_KEYWORDS.fetch(sequencing_platform, sequencing_platform)
  end

  def configured_name
    names = self.class.mapping.fetch(service_name.to_s.strip) do
      raise ApiOperation::Error.new(POINTER, "Unknown Sapio service '#{service_name}' for Sequencescape")
    end
    return names.first if names.one?

    raise ApiOperation::Error.new(POINTER, "Sequencescape cannot determine a single template for '#{service_name}'")
  end
end
