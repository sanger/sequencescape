class SampleManifestGenerator

  include ActiveModel::Validations

  attr_reader :sample_manifest, :params, :user
  
  validates_presence_of :user 

  def initialize(params, user)
    @params = params
    @user = user
  end

  def execute
    if valid?
      @sample_manifest = SampleManifest.create!(params.except(:barcode_printer, :only_first_label, :template).merge(user: user, rapid_generation: true))
      sample_manifest.generate
    end
  end
end