# frozen_string_literal: true

# Checks a payload against the schema named by the sapio_schema_* settings
# in config/environments. It keeps the first MAX_PROBLEMS problems and the
# total, so a mistake repeated across a large payload doesn't give a very
# large response.
class ApiOperation::SchemaCheck
  # The most problems kept
  MAX_PROBLEMS = 100

  # @param payload [Object] the parsed JSON payload
  def initialize(payload)
    @payload = payload
  end

  # @return [Boolean] true if the payload matches the schema
  def valid?
    all_problems.empty?
  end

  # @return [Array<Hash>] the first MAX_PROBLEMS problems, each with
  #   :pointer and :detail
  def problems
    all_problems.first(MAX_PROBLEMS)
  end

  # @return [Integer] how many problems there are
  def total
    all_problems.size
  end

  # @return [Hash] the subject and version of the schema used
  def schema_meta
    { schema: setting(:subject), version: validator.schema.version }
  end

  private

  def all_problems
    @all_problems ||= validator.validate(@payload)
  end

  def validator
    @validator ||= Schemas::Provider.configured.validator_for(
      subject: setting(:subject),
      version: Schemas::Provider.parse_version(setting(:version))
    )
  end

  def setting(name)
    Rails.application.config.try(:"sapio_schema_#{name}")
  end
end
