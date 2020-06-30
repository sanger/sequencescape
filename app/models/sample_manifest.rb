# frozen_string_literal: true

# A SampleManifest is the primary way in which new {Sample samples} enter
# Sequencescape. When the manifest is generated Sequencescape registers
# the labware, and reserves a series of {SangerSampleId Sanger sample ids}
# for the potential samples. It also generates a {SampleManifestExcel}
# spreadsheet which gets sent to the customer.
#
# The labware that gets generate is determined by the {#asset_type} which
# switches out the {#core_behaviour} module {SampleManifest::CoreBehaviour}.
# This is concerned with generating {Labware} and {Receptacle receptacles},
# generating any event specific to the asset type, and setting manifest specific
# properties on {Aliquot}
#
# All {Sample samples} in a given manifest will initially belong to a single
# {Study}, although it is possible for them to become associated with additional
# studies over time.
class SampleManifest < ApplicationRecord
  include Uuid::Uuidable
  include ModelExtensions::SampleManifest
  include SampleManifest::BarcodePrinterBehaviour
  include SampleManifest::CoreBehaviour
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
  belongs_to :tube_rack_purpose, class_name: 'TubeRack::Purpose', inverse_of: :sample_manifests
  has_many :samples, inverse_of: :sample_manifest
  accepts_nested_attributes_for :samples

  has_many :sample_manifest_assets
  has_many :assets, through: :sample_manifest_assets

  serialize :last_errors
  serialize :barcodes

  validates :supplier, presence: true
  validates :study, presence: true
  validates :count, numericality: { only_integer: true, greater_than: 0, allow_blank: false }
  validates :asset_type, presence: true, inclusion: { in: SampleManifest::CoreBehaviour::BEHAVIOURS }

  before_save :default_asset_type

  # Too many errors overflow the text column when serialized. This can affect de-serialization
  # and can even prevent manifest resubmission.
  before_save :truncate_errors

  delegate :printables, :acceptable_purposes, :acceptable_rack_purposes, :labware, :labware=,
           :pending_external_library_creation_requests, :default_purpose, :default_tube_rack_purpose,
           to: :core_behaviour
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
    created_broadcast_event
    nil
  end

  def create_sample_and_aliquot(sanger_sample_id, asset)
    core_behaviour.generate_sample_and_aliquot(sanger_sample_id, asset)
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

  def indexed_manifest_assets
    sample_manifest_assets.includes(*core_behaviour.included_resources).index_by(&:sanger_sample_id)
  end

  # updates the manifest barcode list e.g. after applying a foreign barcode
  def update_barcodes
    self.barcodes = labware.map(&:human_barcode)
    save!
  end

  # Fall back to stock plate by default
  def purpose
    super || default_purpose
  end

  def purpose_id
    super || purpose.id
  end

  def tube_rack_purpose
    super || default_tube_rack_purpose
  end

  def tube_rack_purpose_id
    super || tube_rack_purpose.id
  end

  # Upon upload, sample manifests might generate qc_results for certain
  # specialised fields. We want to keep one qc_assay per sample manifest.
  def qc_assay
    @qc_assay ||= QcAssay.find_by(lot_number: "sample_manifest_id:#{id}")
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def find_or_create_qc_assay!
    @qc_assay ||= QcAssay.find_or_create_by!(lot_number: "sample_manifest_id:#{id}")
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName
end
