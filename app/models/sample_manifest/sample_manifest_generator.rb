class SampleManifestGenerator

  REQUIRED_ATTRIBUTES = [ "template", "count"]

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

  def execute
    if valid?
      ActiveRecord::Base.transaction do
        @sample_manifest = SampleManifest.create!(attributes)
        sample_manifest.generate
        create_download
        true
      end
    else
      false
    end
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

  def attributes
    params.except(:template, :barcode_printer, :only_first_label).merge(user: user, rapid_generation: true, 
      asset_type: params[:asset_type] || configuration.manifest_types.find_by(params[:template]).asset_type)
  end

end