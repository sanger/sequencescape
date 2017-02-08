# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

module ModelExtensions::Order
  module Validations
    def self.included(base)
      base.class_eval do
        extend DelegateValidation
        delegate_validation :request_options_for_validation, as: 'request_options', to: :request_types, if: :validate_request_options?
      end
    end

    # The validation of the request options should happen if we are leaving the building state, or if the
    # request options have been specified.  Once they are specified they are always checked, unless they are
    # completely blanked.
    def validate_request_options?
      not building? or not request_options.blank?
    end
    private :validate_request_options?

    def request_types_delegate_validator
      DelegateValidation::CompositeValidator::CompositeValidator(*::RequestType.find(request_types.flatten).map(&:delegate_validator))
    end

    # If this returns true then we check values that have not been set, otherwise we can ignore them.  This would
    # mean that we should not require values that are unset, until we're moving out of the building state.
    def include_unset_values?
      not building?
    end

    def request_options_for_validation
      OpenStruct.new({ owner: self }.reverse_merge(request_options || {})).tap do |v|
        v.class.delegate(:errors, :include_unset_values?, to: :owner)
      end
    end
  end

  def validate_new_record(assets)
    raise StandardError, 'requested action is not supported on this resource' if not new_record? and asset_group? and assets.present?
    true
  end

  def self.included(base)
    base.class_eval do
      include Validations

      before_validation :merge_in_structured_request_options

      scope :include_study, -> { includes(study: :uuid_object) }
      scope :include_project, -> { includes(project: :uuid_object) }
      scope :include_assets, -> { includes(assets: :uuid_object) }

      has_many :submitted_assets, -> { joins(:asset) }, inverse_of: :order
      has_many :assets, through: :submitted_assets, before_add: :validate_new_record

     scope :that_submitted_asset_id, ->(asset_id) {
       where(submitted_assets: { asset_id: asset_id }).joins(:submitted_assets)
     }

      validate :extended_validation
      def extended_validation
        extended_validators.reduce(true) { |valid, validator| validator.validate_order(self) && valid }
      end

      # The API can create submissions but we have to prevent someone from changing the study
      # and the project once they have been set.
      validates_each(:study, :project) do |record, attr, _value|
        # NOTE: This can get called after the record has been saved but before it has been completely saved, i.e. after_create
        # In this case the original value of the attribute will be nil, so we account for that here.
        attr_value_was, attr_value_is = record.send(:"#{attr}_id_was"), record.send(:"#{attr}_id")
        record.errors.add(attr, 'cannot be changed') if not record.new_record? and attr_value_was != attr_value_is and attr_value_was.present?
      end

      def extended_validators
        ExtendedValidator.for_submission(self)
      end

      extend ClassMethods
    end
  end

  class NonNilHash
    def initialize(key_style_operation = :symbolize_keys)
      @key_style_operation = key_style_operation
      @store = ActiveSupport::HashWithIndifferentAccess.new
    end

    def deep_merge(hash)
      @store.deep_merge!(hash.try(@key_style_operation) || {})
      self
    end

    def [](*keys)
      node_and_leaf(*keys) { |node, leaf| node.fetch(leaf, nil) }
    end

    def []=(*keys_and_values)
      value = keys_and_values.pop
      return if value.nil?
      node_and_leaf(*keys_and_values) { |node, leaf| node[leaf] = value }
    end

    def fetch(*keys_and_default)
      default = keys_and_default.pop
      node_and_leaf(*keys_and_default) { |node, left| node.fetch(left, default) }
    end

    def to_hash
      Hash.new.deep_merge(@store)
    end

    def node_and_leaf(*keys)
      leaf = keys.pop
      node = keys.inject(@store) { |h, k| h[k] ||= ActiveSupport::HashWithIndifferentAccess.new }
      yield(node, leaf)
    end
    private :node_and_leaf
  end

  def request_type_multiplier
    yield(request_types.last.to_s.to_sym) unless request_types.blank?
  end

  def request_options_structured
    NonNilHash.new(:stringify_keys).tap do |json|
      NonNilHash.new.deep_merge(request_options).tap do |attributes|
        json['read_length']                    = attributes[:read_length].try(:to_i)
        json['library_type']                   = attributes[:library_type]
        json['fragment_size_required', 'from'] = attributes[:fragment_size_required_from].try(:to_i)
        json['fragment_size_required', 'to']   = attributes[:fragment_size_required_to].try(:to_i)
        json['bait_library']                   = attributes[:bait_library_name]
        json['sequencing_type']                = attributes[:sequencing_type]
        json['insert_size']                    = attributes[:insert_size].try(:to_i)
        request_type_multiplier { |id| json['number_of_lanes'] = attributes[:multiplier, id] }
      end
    end.to_hash
  end

  def request_options_structured=(values)
    @request_options_structured = NonNilHash.new.tap do |attributes|
      NonNilHash.new(:stringify_keys).deep_merge(values).tap do |json|
        # NOTE: Be careful with the names here to ensure that they match up, exactly with what is in a template.
        # If the template uses symbol names then these need to be symbols too.
        attributes[:read_length]                  = json['read_length']
        attributes['library_type']                = json['library_type']
        attributes['fragment_size_required_from'] = json['fragment_size_required', 'from']
        attributes['fragment_size_required_to']   = json['fragment_size_required', 'to']
        attributes[:bait_library_name]            = json['bait_library']
        attributes[:sequencing_type]              = json['sequencing_type']
        attributes[:insert_size]                  = json['insert_size']
        request_type_multiplier { |id| attributes[:multiplier, id] = json['number_of_lanes'] }
      end
    end.to_hash
  end

  def merge_in_structured_request_options
    self.request_options ||= {}
    self.request_options = self.request_options.deep_merge(@request_options_structured || {})
    true
  end
  private :merge_in_structured_request_options

  def request_type_objects
    return [] if request_types.blank?
    ::RequestType.find(request_types)
  end
end
