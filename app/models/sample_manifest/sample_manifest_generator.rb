class SampleManifestGenerator
  REQUIRED_ATTRIBUTES = ['template', 'count']

  include ActiveModel::Validations

  attr_reader :sample_manifest, :params, :user, :configuration

  validates_presence_of :user, :configuration

  validate :check_required_attributes
  validate :check_template, if: Proc.new { |s| s.configuration.present? }

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

  def print_job
    @print_job ||= LabelPrinter::PrintJob.new(params[:barcode_printer],
                      LabelPrinter::Label::SampleManifestRedirect,
                      only_first_label: only_first_label, sample_manifest: sample_manifest)
  end

  def execute
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
      errors.add(:base, "#{attribute} attribute should be present") unless params[attribute].present?
    end
  end

  def check_template
    errors.add(:base, "#{params[:template]} is not a valid template") unless columns.present?
  end

  def create_download
    download = SampleManifestExcel::Download.new(sample_manifest, columns.dup, configuration.ranges.dup)
    Tempfile.open("sample_manifest_#{sample_manifest.id}.xlsx") do |tempfile|
      download.save(tempfile.path)
      tempfile.open
      sample_manifest.update_attributes!(generated: tempfile, password: download.password)
    end
  end

  def execute_print_job
    if print_job_required?
      if print_job.execute
        print_job_message[:notice] = print_job.success
      else
        print_job_message[:error] = print_job.errors.full_messages.join('; ')
      end
    end
  end

  def attributes
    params.except(:template, :barcode_printer, :only_first_label)
          .merge(user: user, rapid_generation: true, asset_type: asset_type)
  end

  def asset_type
    params[:asset_type].present? ? params[:asset_type] : configuration.manifest_types.find_by(params[:template]).asset_type
  end

  def only_first_label
    ActiveRecord::Type::Boolean.new.type_cast_from_database(params[:only_first_label])
  end
end
