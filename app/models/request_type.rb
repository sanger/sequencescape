class RequestType < ActiveRecord::Base
  class DeprecatedError < RuntimeError; end

  class RequestTypePlatePurpose < ActiveRecord::Base
    set_table_name('request_type_plate_purposes')

    belongs_to :request_type
    validates_presence_of :request_type
    belongs_to :plate_purpose
    validates_presence_of :plate_purpose
    validates_uniqueness_of :plate_purpose_id, :scope => :request_type_id
  end

  include Workflowed
  include Uuid::Uuidable
  include Named

  has_many :requests
  has_many :pipelines_request_types
  has_many :pipelines, :through => :pipelines_request_types

  # Returns a collect of pipelines for which this RequestType is valid control.
  # ...so only valid for ControlRequest producing RequestTypes...
  has_many :control_pipelines, :class_name => 'Pipeline', :foreign_key => :control_request_type_id
  belongs_to :product_line

  # Couple of named scopes for finding billable types
  named_scope :billable, { :conditions => { :billable => true } }
  named_scope :non_billable, { :conditions => { :billable => false } }

  # Defines the acceptable plate purposes or the request type.  Essentially this is used to limit the
  # cherrypick plate types when going into pulldown to the correct list.
  has_many :plate_purposes, :class_name => 'RequestType::RequestTypePlatePurpose'
  has_many :acceptable_plate_purposes, :through => :plate_purposes, :source => :plate_purpose

  MORPHOLOGIES  = [
    LINEAR = 0,   # one-to-one
    CONVERGENT = 1, # many-to-one
    DIVERGENT = 2 # one-to-many
    # we don't do many-to-many so far
  ]

  validates_presence_of :order
  validates_numericality_of :order, :integer_only => true
  validates_numericality_of :morphology, :in => MORPHOLOGIES
  validates_presence_of :request_class_name

  serialize :request_parameters

  delegate :delegate_validator, :to => :request_class

  named_scope :applicable_for_asset, lambda { |asset| 
    {
      :conditions => [
        'asset_type = ?
         AND request_class_name != "ControlRequest"
         AND deprecated IS FALSE',
         asset.asset_type_for_request_types.name
      ]
    }
  }

  # Helper method for generating a request constructor, like 'create!'
  def self.request_constructor(name, options = {})
    target        = options[:target] || :request_class
    target_method = options[:method] || name

    line = __LINE__ + 1
    class_eval(%Q{
      def #{name}(attributes = nil, &block)
        raise RequestType::DeprecatedError if self.deprecated
        attributes ||= {}
        #{target}.#{target_method}(attributes.merge(request_parameters || {})) do |request|
          request.request_type = self
          yield(request) if block_given?
        end.tap do |request|
          requests << request
        end
      end
    }, __FILE__, line)
  end

  request_constructor(:create!)
  request_constructor(:new)
  alias_method(:new_request, :new)

  request_constructor(:create_control!, :target => 'ControlRequest', :method => :create!)

  def request_class
    request_class_name.constantize
  end

  def request_class=(request_class)
    self.request_class_name = request_class.name
  end

  def quarantine_create_asset_at_submission_time?
    # temporary
    # we should had an attribute for that
    [6,7, 8].include? id
  end

  def order_with_default(default=2^31)
    order || default
  end

  def quarantine_is_for_library_creation?
    # TODO: this should either be an attribute in the request_types table or a specific class hierarchy is required
    [ :library_creation, :multiplexed_library_creation ].include?(self.key.to_sym)
  end

  def quaratine_is_for_sequencing?
    # TODO: this should either be an attribute in the request_types table or a specific class hierarchy is required
    [ :single_ended_sequencing, :paired_end_sequencing ].include?(self.key.to_sym)
  end

  def self.dna_qc
    @dna_qc ||= RequestType.find_by_key("dna_qc")
  end

  def self.genotyping
    @genotyping ||= RequestType.find_by_key("genotyping")
  end

  def self.transfer
    @transfer ||= RequestType.find_by_key("transfer")
  end

  def extract_metadata_from_hash(request_options)
    # WARNING: we need a copy of the options (we delete stuff from attributes)
    return {} unless request_options
    attributes = request_options.symbolize_keys
    common_attributes = request_class::Metadata.attribute_details.map(&:name)
    common_attributes.concat(request_class::Metadata.association_details.map(&:assignable_attribute_name))
    attributes.delete_if { |k,_| not common_attributes.include?(k) }
  end

  def asset_type_class
    asset_type ? asset_type.constantize : Asset
  end
end
