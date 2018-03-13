# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

class RequestType < ApplicationRecord
  include RequestType::Validation

  class DeprecatedError < RuntimeError; end

  class RequestTypePlatePurpose < ApplicationRecord
    self.table_name = ('request_type_plate_purposes')

    belongs_to :request_type
    validates_presence_of :request_type
    belongs_to :plate_purpose
    validates_presence_of :plate_purpose
    validates_uniqueness_of :plate_purpose_id, scope: :request_type_id
  end

  include Uuid::Uuidable
  include SharedBehaviour::Named

  MORPHOLOGIES = [
    LINEAR = 0, # one-to-one
    CONVERGENT = 1, # many-to-one
    DIVERGENT = 2 # one-to-many
    # we don't do many-to-many so far
  ]

  has_many :requests, inverse_of: :request_type
  has_many :pipelines_request_types, inverse_of: :request_type
  has_many :pipelines, through: :pipelines_request_types
  has_many :library_types_request_types, inverse_of: :request_type, dependent: :destroy
  has_many :library_types, through: :library_types_request_types
  has_many :request_type_validators, class_name: 'RequestType::Validator', dependent: :destroy

  belongs_to :pooling_method, class_name: 'RequestType::PoolingMethod'
  has_many :request_type_extended_validators, class_name: 'ExtendedValidator::RequestTypeExtendedValidator'
  has_many :extended_validators, through: :request_type_extended_validators, dependent: :destroy
  # Returns a collect of pipelines for which this RequestType is valid control.
  # ...so only valid for ControlRequest producing RequestTypes...
  has_many :control_pipelines, class_name: 'Pipeline', foreign_key: :control_request_type_id
  # Defines the acceptable plate purposes or the request type.  Essentially this is used to limit the
  # cherrypick plate types when going into pulldown to the correct list.
  has_many :plate_purposes, class_name: 'RequestType::RequestTypePlatePurpose'
  has_many :acceptable_plate_purposes, through: :plate_purposes, source: :plate_purpose

  # While a request type describes what a request is, a request purpose describes why it is being done.
  # ie. standrad, qc, internal
  # The value on request type acts as a default for requests
  enum request_purpose: {
    standard: 1,
    internal: 2,
    qc: 3,
    control: 4
  }

  belongs_to :product_line
  # The target asset can either be described by a purpose, or by the target asset type.
  belongs_to :target_purpose, class_name: 'Purpose'

  belongs_to :billing_product_catalogue, class_name: 'Billing::ProductCatalogue'

  validates_presence_of :request_purpose
  validates_presence_of :order
  validates_numericality_of :order, integer_only: true
  validates_numericality_of :morphology, in: MORPHOLOGIES
  validates :request_class, presence: true, inclusion: { in: ->(_) { [Request, *Request.descendants] } }

  serialize :request_parameters

  delegate :accessioning_required?, to: :request_class

  # Couple of named scopes for finding billable types
  scope :billable, -> { where(billable: true) }
  scope :non_billable, -> { where(billable: false) }
  scope :needing_target_asset, -> { where(target_purpose: nil, target_asset_type: nil) }
  scope :applicable_for_asset, ->(asset) {
                                 where([
                                   'asset_type = ?
                                    AND request_class_name != "ControlRequest"
                                    AND deprecated IS FALSE',
                                   asset.asset_type_for_request_types.name
                                 ])
                               }

  # Temporary scope: Remove once converted to enum
  scope :standard, ->() { where(request_purpose: :standard) }

  def construct_request(construct_method, attributes, klass = request_class)
    raise RequestType::DeprecatedError if deprecated?
    new_request = klass.public_send(construct_method, attributes) do |request|
      request.request_type = self
      request.request_purpose ||= request_purpose
      request.billing_product = find_product_for_request(request)
      yield(request) if block_given?
    end
    # Prevent us caching all our requests
    requests.reset
    new_request
  end

  def create!(attributes = {}, &block)
    construct_request(:create!, attributes, &block)
  end

  def new(attributes = {}, &block)
    construct_request(:new, attributes, &block)
  end

  def create_control!(attributes = {}, &block)
    construct_request(:create!, attributes, ControlRequest, &block)
  end

  def self.dna_qc
    find_by(key: 'dna_qc') or raise 'Cannot find dna_qc request type'
  end

  def self.genotyping
    find_by(key: 'genotyping') or raise 'Cannot find genotyping request type'
  end

  def request_class
    request_class_name&.constantize
  end

  def request_class=(request_class)
    self.request_class_name = request_class.name
  end

  def extract_metadata_from_hash(request_options)
    # WARNING: we need a copy of the options (we delete stuff from attributes)
    return {} unless request_options
    attributes = request_options.symbolize_keys
    common_attributes = request_class::Metadata.attribute_details.map(&:name)
    common_attributes.concat(request_class::Metadata.association_details.map(&:assignable_attribute_name))
    attributes.delete_if { |k, _| not common_attributes.include?(k) }
  end

  def targets_lanes?
    (target_asset_type == 'Lane') or (name =~ /\ssequencing$/)
  end

  def needs_target_asset?
    target_purpose.nil? && target_asset_type.blank?
  end

  def create_target_asset!(&block)
    case
    when target_purpose.present?  then target_purpose.create!(&block)
    when target_asset_type.blank? then nil
    else                               target_asset_type.constantize.create!(&block)
    end
  end

  def default_library_type
    library_types.find_by(library_types_request_types: { is_default: true })
  end

  def find_product_for_request(request)
    billing_product_catalogue.find_product_for_request(request) if billing_product_catalogue.present?
  end

  delegate :pool_count,             to: :pooling_method
  delegate :pool_index_for_asset,   to: :pooling_method
  delegate :pool_index_for_request, to: :pooling_method
end
