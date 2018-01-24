class SampleManifest::Uploader
  include ActiveModel::Validations

  attr_reader :filename, :configuration, :tag_group, :upload, :user

  validates_presence_of :filename, :configuration, :tag_group, :user

  validate :check_upload

  delegate :processed?, to: :upload

  def initialize(filename, configuration, user)
    @filename = filename
    @configuration = configuration || SampleManifestExcel::NullConfiguration.new
    @user = user
    @tag_group = create_tag_group
    @upload = SampleManifestExcel::Upload::Base.new(filename: filename, column_list: self.configuration.columns.all, start_row: SampleManifestExcel::FIRST_ROW)
  end

  def run!
    if valid?
      upload.process(tag_group)
      upload.broadcast_sample_manifest_updated_event(user)
      upload.complete if upload.processed?
      # Delayed::Job.enqueue SampleManifestUploadProcessingJob.new(upload, tag_group)
    else
      false
    end
  end

  private

  def create_tag_group
    if configuration.tag_group.present?
      TagGroup.find_or_create_by(name: configuration.tag_group)
    end
  end

  def check_upload
    unless upload.valid?
      upload.errors.each do |key, value|
        errors.add key, value
      end
    end
  end
end
