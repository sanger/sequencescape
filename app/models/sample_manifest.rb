class SampleManifest < ApplicationRecord
  include Uuid::Uuidable
  include ModelExtensions::SampleManifest
  include SampleManifest::BarcodePrinterBehaviour
  include SampleManifest::SampleTubeBehaviour
  include SampleManifest::MultiplexedLibraryBehaviour
  include SampleManifest::LibraryBehaviour
  include SampleManifest::CoreBehaviour
  include SampleManifest::PlateBehaviour
  include SampleManifest::InputBehaviour
  include SampleManifest::SharedTubeBehaviour
  include SampleManifest::LongReadBehaviour
  extend SampleManifest::StateMachine
  extend Document::Associations

  # While the maximum length of the column is 65536 we place a shorter restriction
  # to allow for:
  # 1) Subsequent serialization by the delayed job
  # 2) The addition of a 'too many errors' message
  LIMIT_ERROR_LENGTH = 50000
  # In addition we truncate individual messages, this ensures that we don't
  # inadvertently filter out ALL our errors if the first message is especially long.
  # We don't re-use the figure above as that would prevent any display of subsequent
  # messages, which probably indicate a different issue.
  INDIVIDUAL_ERROR_LIMIT = LIMIT_ERROR_LENGTH / 10

  # Samples have a similar issue when generating update events
  # This limit sets a very comfortable safety margin.
  SAMPLES_PER_EVENT = 3000

  module Associations
    def self.included(base)
      base.has_many(:sample_manifests)
    end
  end

  has_uploaded_document :uploaded, differentiator: 'uploaded'
  has_uploaded_document :generated, differentiator: 'generated'

  attr_accessor :override, :only_first_label

  class_attribute :spreadsheet_offset
  class_attribute :spreadsheet_header_row
  self.spreadsheet_offset = 9
  self.spreadsheet_header_row = 8

  # Needed for the UI to work!
  def barcode_printer; end

  def template; end

  belongs_to :supplier
  belongs_to :study
  belongs_to :project
  belongs_to :user
  belongs_to :purpose
  has_many :samples, inverse_of: :sample_manifest
  accepts_nested_attributes_for :samples

  has_many :sample_manifest_assets
  has_many :assets, through: :sample_manifest_assets

  serialize :last_errors
  serialize :barcodes

  validates_presence_of :supplier
  validates_presence_of :study
  validates_numericality_of :count, only_integer: true, greater_than: 0, allow_blank: false

  before_save :default_asset_type

  # Too many errors overflow the text column when serialized. This can affect de-serialization
  # and can even prevent manifest resubmission.
  before_save :truncate_errors

  delegate :printables, :acceptable_purposes, :labware, :labware=, :pending_external_library_creation_requests, to: :core_behaviour
  delegate :name, to: :supplier, prefix: true

  def truncate_errors
    if last_errors && last_errors.join.length > LIMIT_ERROR_LENGTH

      # First we truncate individual error messages. This ensures that it the first message is already
      # longer than out max limit, we still show something.
      full_last_errors = last_errors.map { |error| error.truncate(INDIVIDUAL_ERROR_LIMIT) }

      removed_errors = 0

      while full_last_errors.join.length > LIMIT_ERROR_LENGTH
        full_last_errors.pop
        removed_errors += 1
      end

      full_last_errors << "There were too many errors to record. #{removed_errors} additional errors are not shown." if removed_errors.positive?

      self.last_errors = full_last_errors

    end
  end

  def default_asset_type
    self.asset_type = 'plate' if asset_type.blank?
  end

  def name
    "Manifest_#{id}"
  end

  def default_filename
    "#{study_id}stdy_manifest_#{id}_#{created_at.to_formatted_s(:dmy)}"
  end

  # TODO[xxx] Consider index to make it faster
  scope :pending_manifests, ->() {
    order('sample_manifests.id DESC')
      .joins('LEFT OUTER JOIN documents ON documentable_type="SampleManifest" AND documentable_id=sample_manifests.id AND documentable_extended="uploaded"')
      .where('documents.id IS NULL')
  }

  scope :completed_manifests, ->() {
    order('sample_manifests.updated_at DESC')
      .joins('LEFT OUTER JOIN documents ON documentable_type="SampleManifest" AND documentable_id=sample_manifests.id AND documentable_extended="uploaded"')
      .where('documents.id IS NOT NULL')
  }

  def generate
    ActiveRecord::Base.transaction do
      self.barcodes = []
      core_behaviour.generate
    end
    created_broadcast_event if broadcast_event_subjects_ready?
    nil
  end

  def create_sample_and_aliquot(sanger_sample_id, asset)
    core_behaviour.generate_sample_and_aliquot(sanger_sample_id, asset)
  end

  def broadcast_event_subjects_ready?
    labware.present? && study.present?
  end

  def create_sample(sanger_sample_id)
    Sample.create!(name: sanger_sample_id, sanger_sample_id: sanger_sample_id, sample_manifest: self).tap do |sample|
      sample.events.created_using_sample_manifest!(user)
    end
  end

  def created_broadcast_event
    BroadcastEvent::SampleManifestCreated.create!(seed: self, user: user)
  end

  def updated_broadcast_event(user_updating_manifest, updated_samples_ids)
    # We chunk samples into groups of 3000 to avoid issues with the column size in broadcast_events.properties
    # In practice we have 11 characters per sample with current id lengths. This allows for up to 21 characters
    updated_samples_ids.each_slice(SAMPLES_PER_EVENT) do |chunked_sample_ids|
      BroadcastEvent::SampleManifestUpdated.create!(seed: self, user: user_updating_manifest, properties: { updated_samples_ids: chunked_sample_ids })
    end
  end

  private

  def generate_sanger_ids(count = 1)
    Array.new(count) { SangerSampleId::Factory.instance.next! }
  end
end
