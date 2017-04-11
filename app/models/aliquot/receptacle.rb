# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Aliquot::Receptacle < Asset
  include Transfer::State
  include Aliquot::Remover

  has_many :transfer_requests, class_name: 'TransferRequest', foreign_key: :target_asset_id
  has_many :transfer_requests_as_source, class_name: 'TransferRequest', foreign_key: :asset_id
  has_many :transfer_requests_as_target, class_name: 'TransferRequest', foreign_key: :target_asset_id

  has_many :requests, inverse_of: :asset, foreign_key: :asset_id
  has_one  :source_request, ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :target_asset_id
  has_many :requests_as_source, ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :asset_id
  has_many :requests_as_target, ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :target_asset_id

  has_many :creation_batches, class_name: 'Batch', through: :requests_as_target, source: :batch
  has_many :source_batches, class_name: 'Batch', through: :requests_as_source, source: :batch

  def default_state
    nil
  end

  SAMPLE_PARTIAL = 'assets/samples_partials/asset_samples'

  # A receptacle can hold many aliquots.  For example, a multiplexed library tube will contain more than
  # one aliquot.
  has_many :aliquots, ->() { order(tag_id: :asc, tag2_id: :asc) }, foreign_key: :receptacle_id, autosave: true, dependent: :destroy, inverse_of: :receptacle
  has_one :primary_aliquot, ->() { order(:created_at).readonly }, class_name: 'Aliquot', foreign_key: :receptacle_id

  has_many :tags, through: :aliquots

  # Our receptacle needs to report its tagging status based on the most highly tagged aliquot. This retrieves it
  has_one :most_tagged_aliquot, ->() { order(tag2_id: :desc, tag_id: :desc).readonly }, class_name: 'Aliquot', foreign_key: :receptacle_id

  # Named scopes for the future
  scope :include_aliquots, -> { includes(aliquots: [:sample, :tag, :bait_library]) }
  scope :include_aliquots_for_api, -> { includes(aliquots: [{ sample: [:uuid_object, :study_reference_genome, { sample_metadata: :reference_genome }] }, { tag: :tag_group }, :bait_library]) }
  scope :for_summary, -> { includes(:map, :samples, :studies, :projects) }
  scope :include_creation_batches, -> { includes(:creation_batches) }
  scope :include_source_batches, -> { includes(:source_batches) }

  scope :for_study_and_request_type, ->(study, request_type) { joins(:aliquots, :requests).where(aliquots: { study_id: study }).where(requests: { request_type_id: request_type }) }

  # This is a lambda as otherwise the scope selects Aliquot::Receptacles
  scope :with_aliquots, -> { joins(:aliquots) }

  # Provide some named scopes that will fit with what we've used in the past
  scope :with_sample_id, ->(id)     { where(aliquots: { sample_id: Array(id)     }).joins(:aliquots) }
  scope :with_sample,    ->(sample) { where(aliquots: { sample_id: Array(sample) }).joins(:aliquots) }

  # Scope for caching the samples of the receptacle
  scope :including_samples, -> { includes(samples: :studies) }

  # TODO: Remove these at some point in the future as they're kind of wrong!
  has_one :sample, through: :primary_aliquot
  deprecate sample: 'receptacles may contain multiple samples. This method just returns the first.'

  def sample=(sample)
    aliquots.clear
    aliquots << Aliquot.new(sample: sample)
  end
  deprecate :sample=

  def sample_id
    primary_aliquot.try(:sample_id)
  end
  deprecate :sample_id

  has_one :get_tag, through: :primary_aliquot, source: :tag
  deprecate :get_tag

  def tag
    get_tag.try(:map_id) || ''
  end
  deprecate :tag

  delegate :tag_count_name, to: :most_tagged_aliquot, allow_nil: true

  # Returns the map_id of the first and last tag in an asset
  # eg 1-96.
  # Caution: Used on barcode labels. Avoid using elsewhere as makes assumptions
  #          about tag behaviour which may change shortly.
  # @return [String,nil] Returns nil is no tags, the map_id is a single tag, or the first and
  #                      last map id separated by a hyphen if multiple tags.
  #
  def tag_range
    map_ids = tags.order(:map_id).pluck(:map_id)
    case map_ids.length
    when 0; then nil
    when 1; then map_ids.first
    else "#{map_ids.first}-#{map_ids.last}"
    end
  end

  def primary_aliquot_if_unique
    primary_aliquot if aliquots.count == 1
  end

  def type
    self.class.name.underscore
  end

  def specialized_from_manifest=(*args); end

  def library_information; end

  def library_information=(*args); end

  def assign_tag2(tag)
    aliquots.each do |aliquot|
      aliquot.tag2 = tag
      aliquot.save!
    end
  end

  # Library types are still just a string on aliquot.
  def library_types
    aliquots.pluck(:library_type).uniq
  end

  has_many :studies, through: :aliquots
  has_many :projects, through: :aliquots
  has_many :samples, through: :aliquots

  # Contained samples also works on eg. plate
  alias_attribute :contained_samples, :samples
end
