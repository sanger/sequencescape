class RequestType < ActiveRecord::Base
  include Workflowed
  include Uuid::Uuidable
  include Named

  has_many :requests
  has_many :pipelines

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

  named_scope :applicable_for_asset, lambda { |asset| { :conditions => { :asset_type => asset.asset_type_for_request_types.name } } }

  def new_request(params={})
    params.merge!(request_parameters) if request_parameters
    params[:request_type] = self

    request = request_class.new(params)
    return request
  end

  def create!(attributes = nil)
    attributes ||= {}
    requests.create!(attributes.merge(request_parameters || {}))
  end

  def new(attributes = nil)
    attributes ||= {}
    requests.new(attributes.merge(request_parameters || {}))
  end

  def request_class
    request_class_name.constantize
  end

  def request_class=(request_class)
    self.request_class_name = request_class.name
  end

  def for_multiplexing?
    request_class.ancestors.include?(MultiplexedLibraryCreationRequest) || request_class.ancestors.include?(PulldownMultiplexedLibraryCreationRequest) || request_class.ancestors.include?(CherrypickForPulldownRequest)
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
    RequestType.find_by_key("dna_qc")
  end
  
  def self.genotyping
    RequestType.find_by_key("genotyping")
  end

  def extract_metadata_from_hash(request_options)
    # WARNING: we need a copy of the options (we delete stuff from attributes)
    return {} unless request_options
    attributes = request_options.symbolize_keys
    common_attributes = request_class::Metadata.attribute_details.map(&:name)
    attributes.delete_if { |k,_| not common_attributes.include?(k) }
  end

  def asset_type_class
    asset_type ? asset_type.constantize : Asset
  end
end
