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

  def columns
    @columns ||= configuration.columns.find(params[:template])
  end

  def print_job_required?
    params[:barcode_printer].present?
  end

  # Creates and returns a print job for the sample manifest.
  #
  # This method initializes a new `LabelPrinter::PrintJob` object with the provided parameters.
  # The print job is responsible for printing labels for the sample manifest, using the specified
  # barcode printer and label template.
  #
  # @return [LabelPrinter::PrintJob] The print job object configured with the provided parameters.
  #
  # Parameters used:
  # - `params[:barcode_printer]`: The barcode printer to use for printing.
  # - `LabelPrinter::Label::SampleManifestRedirect`: The label type for the sample manifest.
  # - `only_first_label`: A boolean indicating whether only the first label should be printed.
  # - `sample_manifest`: The sample manifest object for which labels are being printed.
  # - `label_template_name`: The label template to use, determined by `label_template_for_2d_barcodes`.
  #    If not given, the template given in the database is used.
  # - `params[:barcode_type]`: The type of barcode being used.
  #
  # Example:
  #   print_job
  #   # => #<LabelPrinter::PrintJob:0x00007f8c8c1b2e10>
  #
  # Caching:
  # - The method memoizes the print job object in the `@print_job` instance variable to avoid
  #   creating multiple instances for the same parameters.
  def print_job
    @print_job ||=
      LabelPrinter::PrintJob.new(
        params[:barcode_printer],
        LabelPrinter::Label::SampleManifestRedirect,
        only_first_label: only_first_label,
        sample_manifest: sample_manifest,
        label_template_name: label_template_for_2d_barcodes,
        barcode_type: params[:barcode_type]
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

  # Determines the label template to use for 2D barcodes.
  #
  # This method checks if the provided barcode type matches the configured 2D barcode type
  # and if the asset type of the sample manifest is one of the 'tube' types.
  # If both conditions are met, it returns the configured label template for 2D barcodes.
  # Otherwise, it returns `nil`.
  #
  # @return [String, nil] The label template for 2D barcodes if conditions are met, otherwise `nil`.
  #
  # Conditions:
  # - The `params[:barcode_type]` must match the configured 2D barcode type.
  # - The `sample_manifest.asset_type` must be a tube type.
  #
  # Example:
  #   label_template_for_2d_barcodes
  #   # => "2D_Label_Template" (if conditions are met)
  #   # => nil (if conditions are not met)
  def label_template_for_2d_barcodes
    if params[:barcode_type] == Rails.application.config.tube_manifest_barcode_config[:barcode_type_labels]['2d'] &&
        SampleManifest.tube_asset_types.include?(sample_manifest.asset_type)
      Rails.application.config.tube_manifest_barcode_config[:two_dimensional_label_template]
    end
  end

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
    params.except(:template, :barcode_printer, :only_first_label, :barcode_type).merge(
      user:,
      asset_type:,
      rows_per_well:,
      invalid_wells:
    )
  end

  def asset_type
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
