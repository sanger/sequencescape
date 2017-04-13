# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class SampleManifest < ActiveRecord::Base
  include Uuid::Uuidable
  include ModelExtensions::SampleManifest
  include SampleManifest::BarcodePrinterBehaviour
  include SampleManifest::SampleTubeBehaviour
  include SampleManifest::MultiplexedLibraryBehaviour
  include SampleManifest::CoreBehaviour
  include SampleManifest::PlateBehaviour
  include SampleManifest::InputBehaviour
  include SampleManifest::SharedTubeBehaviour
  extend SampleManifest::StateMachine
  extend Document::Associations

  # While the maximum length of the column is 65536 we place a shorter restriction
  # to allow for:
  # 1) Subsequent serialization by the delayed job
  # 2) The addition of a 'too many errors' message
  LIMIT_ERROR_LENGTH = 50000

  module Associations
    def self.included(base)
      base.has_many(:sample_manifests)
    end
  end

  has_uploaded_document :uploaded, differentiator: 'uploaded'
  has_uploaded_document :generated, differentiator: 'generated'

  attr_accessor :override
  attr_reader :manifest_errors

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
  serialize :last_errors
  serialize :barcodes

  validates_presence_of :supplier
  validates_presence_of :study
  validates_numericality_of :count, only_integer: true, greater_than: 0, allow_blank: false

  before_save :default_asset_type

  # Too many errors overflow the text column when serialized. This can affect de-serialization
  # and can even prevent manifest resubmission.
  before_save :truncate_errors

  delegate :printables, to: :core_behaviour

  def truncate_errors
    if last_errors && last_errors.join.length > LIMIT_ERROR_LENGTH

      full_last_errors = last_errors

      removed_errors = 0

      while full_last_errors.join.length > LIMIT_ERROR_LENGTH
        full_last_errors.pop
        removed_errors += 1
      end

      full_last_errors << "There were too many errors to record. #{removed_errors} additional errors are not shown."

      self.last_errors = full_last_errors

    end
  end

  def only_first_label
    false
  end

  def default_asset_type
    self.asset_type = 'plate' if asset_type.blank?
  end

  def name
    "Manifest_#{id}"
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
    @manifest_errors = []

    ActiveRecord::Base.transaction do
      self.barcodes = []
      core_behaviour.generate
    end
    nil
  end

  def create_sample(sanger_sample_id)
    Sample.create!(name: sanger_sample_id, sanger_sample_id: sanger_sample_id, sample_manifest: self).tap do |sample|
      sample.events.created_using_sample_manifest!(user)
    end
  end

  def generate_sanger_ids(count = 1)
    (1..count).map { |_| SangerSampleId::Factory.instance.next! }
  end
  private :generate_sanger_ids

  def generate_study_samples(study_samples_data)
    study_sample_fields = [:study_id, :sample_id]
    study_samples_data.each do |study_sample|
      StudySample.create!(study_id: study_sample.first, sample_id: study_sample.last)
    end
  end
end
