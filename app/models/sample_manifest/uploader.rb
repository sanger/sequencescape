# frozen_string_literal: true

#
# Class SampleManifest::Uploader provides an interface
# for uploading sample manifests from a controller
#
# @author Genome Research Ltd.
#
class SampleManifest::Uploader
  include ActiveModel::Validations

  attr_reader :file, :configuration, :tag_group, :upload, :user, :override

  validates :tag_group, presence: { message: 'is not correctly configured for manifest generation' }
  validates :file, :configuration, :user, presence: true
  validate :check_upload

  delegate :processed?, :study, to: :upload

  def initialize(file, configuration, user, override)
    @file = file
    @configuration = configuration || SequencescapeExcel::NullObjects::NullConfiguration.new
    @user = user
    @override = override
    @tag_group = create_tag_group
    @upload = SampleManifestExcel::Upload::Base.new(
      file: file,
      column_list: self.configuration.columns.all,
      override: override
    )
  end

  def run!
    return false unless valid?

    if upload.process(tag_group)
      upload.complete
      upload.broadcast_sample_manifest_updated_event(user)
      true
    else
      extract_errors
      upload.fail
      false
    end
  end

  private

  def create_tag_group
    TagGroup.find_or_create_by!(name: configuration.tag_group) if configuration.tag_group.present?
  end

  def check_upload
    return true if upload.valid?

    extract_errors
  end

  def extract_errors
    upload.errors.each do |key, value|
      errors.add key, value
    end
  end
end
