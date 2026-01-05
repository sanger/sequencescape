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
  validate :check_sample_manifest_upload

  delegate :processed?, :study, to: :upload

  def initialize(file, configuration, user, override)
    @file = file
    @configuration = configuration || SequencescapeExcel::NullObjects::NullConfiguration.new
    @user = user
    @override = override
    @tag_group = create_tag_group
    @upload =
      SampleManifestExcel::Upload::Base.new(file: file, column_list: self.configuration.columns.all, override: override)
  end

  def run! # rubocop:disable Metrics/MethodLength
    # Validation outside the transaction because we want to return the errors
    return false unless valid?

    # Start the upload so that we can prevent concurrent uploads
    upload.sample_manifest.start!

    # Rails 6.1 doesn't allow return value from transaction block
    success =
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless process_upload_and_callbacks

        true
      end

    # Return from the function if the transaction succeeded
    return true if success

    # Else, return false and extract the errors
    extract_errors
    upload.fail
    false
  end

  private

  def process_upload_and_callbacks
    return false unless upload.process(tag_group)

    upload.sample_manifest.finished!
    upload.broadcast_sample_manifest_updated_event(user)
    upload.register_stock_resources
    upload.trigger_accessioning(user) if Flipper.enabled?(:y25_714_accession_on_manifest_upload)
    true
  end

  def create_tag_group
    TagGroup.find_or_create_by!(name: configuration.tag_group) if configuration.tag_group.present?
  end

  def check_upload
    return true if upload.valid?

    extract_errors
  end

  def check_sample_manifest_upload
    # Refetch the sample manifest to ensure it is in it's newest state
    upload.sample_manifest&.reload
    return true unless upload.sample_manifest&.state == 'processing'

    errors.add(
      :base,
      'A version of this sample manifest is already being processed, please wait until it has completed.'
    )
  end

  def extract_errors
    upload.errors.each { |error| errors.add error.attribute, error.message }
  end
end
