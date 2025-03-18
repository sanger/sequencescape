# frozen_string_literal: true

#
# Class SampleManifest::Generator provides an interface for generating
# sample manifests from the controller
#
# @author Genome Research Ltd.
#
class SampleManifest::Generator
  REQUIRED_ATTRIBUTES = %w[template count].freeze

  include ActiveModel::Validations

  attr_reader :sample_manifest, :params, :user, :configuration

  validates :user, :configuration, presence: true

  validate :check_required_attributes
  validate :check_template, if: proc { |s| s.configuration.present? }

  def self.model_name
    ActiveModel::Name.new(SampleManifest)
  end

  def initialize(params, user, configuration)
    @configuration = configuration
    @user = user
    @params = params
  end

  # Retrieves and caches the columns for the current template configuration.
  # This method first fetches the columns based on the provided template parameter.
  # Then, it applies conditional formatting updates based on the asset type
  # using the `SampleManifest::ColumnConditionalFormatUpdater` class.
  #
  # The conditional formatting is adjusted dynamically depending on whether
  # the asset type requires specific formatting rules (e.g., for library assets).
  #
  # @return [Array<Column>] The columns associated with the specified template, with conditional formatting
  #         updated if any.

  def columns
    @columns ||= configuration.columns.find(params[:template])
    return unless asset_type
    conditional_updater = SampleManifest::ColumnConditionalFormatUpdater.new(columns: @columns, asset_type: asset_type)
    conditional_updater.update_column_formatting_by_asset_type
  end

  def print_job_required?
    params[:barcode_printer].present?
  end

  def print_job
    @print_job ||=
      LabelPrinter::PrintJob.new(
        params[:barcode_printer],
        LabelPrinter::Label::SampleManifestRedirect,
        only_first_label:,
        sample_manifest:
      )
  end

  def execute # rubocop:todo Metrics/MethodLength
    if valid?
      ActiveRecord::Base.transaction do
        @sample_manifest = SampleManifest.create!(attributes)
        sample_manifest.generate
        create_download
        execute_print_job
        true
      end
    else
      false
    end
  end

  def print_job_message
    @print_job_message ||= {}
  end

  private

  def check_required_attributes
    REQUIRED_ATTRIBUTES.each do |attribute|
      errors.add(:base, "#{attribute} attribute should be present") if params[attribute].blank?
    end
  end

  def check_template
    errors.add(:base, "#{params[:template]} is not a valid template") if columns.blank?
  end

  def create_download
    download = SampleManifestExcel::Download.new(sample_manifest, columns.dup, configuration.ranges.dup)
    Tempfile.open("sample_manifest_#{sample_manifest.id}.xlsx") do |tempfile|
      download.save(tempfile.path)
      tempfile.open
      sample_manifest.update!(generated: tempfile, password: download.password)
    end
  end

  def execute_print_job
    return unless print_job_required?

    if print_job.execute
      print_job_message[:notice] = print_job.success
    else
      print_job_message[:error] = print_job.errors.full_messages.join('; ')
    end
  end

  def attributes
    params.except(:template, :barcode_printer, :only_first_label).merge(
      user:,
      asset_type:,
      rows_per_well:,
      invalid_wells:
    )
  end

  def asset_type
    return unless configuration.manifest_types.find_by(params[:template])
    configuration.manifest_types.find_by(params[:template]).asset_type
  end

  # Retrieves the value of the rows_per_well attribute from the manifest_types.yml config.
  # If the attribute is not set, it returns nil.
  def rows_per_well
    configuration.manifest_types.find_by(params[:template]).rows_per_well
  end

  def invalid_wells
    configuration.manifest_types.find_by(params[:template]).invalid_wells
  end

  def only_first_label
    ActiveRecord::Type::Boolean.new.cast(params[:only_first_label])
  end
end
