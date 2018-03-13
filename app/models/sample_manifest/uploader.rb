# frozen_string_literal: true

#
# Class SampleManifest::Uploader provides an interface
# for uploading sample manifests from a controller
#
# @author Genome Research Ltd.
#
class SampleManifest::Uploader
  include ActiveModel::Validations

  attr_reader :filename, :configuration, :tag_group, :upload, :user

  validates :filename, :configuration, :tag_group, :user, presence: true

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
    TagGroup.find_or_create_by(name: configuration.tag_group) if configuration.tag_group.present?
  end

  def check_upload
    return true if upload.valid?
    upload.errors.each do |key, value|
      errors.add key, value
    end
  end
end
