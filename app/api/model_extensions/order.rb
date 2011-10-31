module ModelExtensions::Order
  module Validations
    def self.included(base)
      base.class_eval do
        extend DelegateValidation
        delegate_validation :request_options_for_validation, :to => :request_types, :if => :validate_request_options?
      end
    end

    # The validation of the request options should happen if we are leaving the building state, or if the
    # request options have been specified.  Once they are specified they are always checked, unless they are
    # completely blanked.
    def validate_request_options?
      self.left_building_state? or not self.request_options.blank?
    end
    private :validate_request_options?

    def request_types_delegate_validator
      DelegateValidation::CompositeValidator::CompositeValidator(*::RequestType.find(self.request_types.flatten).map(&:delegate_validator))
    end

    def request_options_for_validation
      OpenStruct.new({ :owner => self }.reverse_merge(self.request_options || {})).tap do |v|
        v.class.delegate :errors, :to => :owner
      end 
    end
  end

  def self.included(base)
    base.class_eval do
      include Validations

      named_scope :include_study,   :include => { :study => :uuid_object }
      named_scope :include_project, :include => { :project => :uuid_object }
      named_scope :include_assets,  :include => { :assets => :uuid_object }

      has_many :submitted_assets
      has_many :assets, :through => :submitted_assets do
        def replace(new_values)
          raise StandardError, 'requested action is not supported on this resource' if not proxy_owner.new_record? and  proxy_owner.send(:asset_group?) and not empty?
          super
        end
      end

      named_scope :that_submitted_asset_id, lambda { |asset_id|
        { :conditions => { :submitted_assets => { :asset_id => asset_id } }, :joins => :submitted_assets }
      }

      # The API can create submissions but we have to prevent someone from changing the study
      # and the project once they have been set.
      validates_each(:study, :project) do |record, attr, value|
        record.errors.add(attr, 'cannot be changed') if not record.new_record? and record.send(:"#{attr}_id_was") != record.send(:"#{attr}_id")
      end

      extend ClassMethods
    end
  end

  class NonNilHash 
    def initialize(key_style_operation = :symbolize_keys)
      @key_style_operation = key_style_operation
      @store = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }
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

    def to_hash
      Hash.new.deep_merge(@store)
    end

    def node_and_leaf(*keys, &block)
      leaf = keys.pop
      node = keys.inject(@store) { |h,k| h[k] }
      yield(node, leaf)
    end
    private :node_and_leaf
  end

  def request_type_multiplier(&block)
    yield(request_types.last.to_s.to_sym) unless request_types.blank?
  end

  def request_options_structured
    NonNilHash.new(:stringify_keys).tap do |json|
      NonNilHash.new.deep_merge(self.request_options).tap do |attributes|
        json['read_length']                    = attributes[:read_length]
        json['library_type']                   = attributes[:library_type]
        json['fragment_size_required', 'from'] = attributes[:fragment_size_required_from]
        json['fragment_size_required', 'to']   = attributes[:fragment_size_required_to]
        json['bait_library']                   = attributes[:bait_library_name]
        request_type_multiplier { |id| json['number_of_lanes'] = attributes[:multiplier, id] }
      end
    end.to_hash
  end
  
  def request_options_structioned_normalised
    structured_options = request_options_structured
    return nil if structured_options.blank?
    ['read_length', 'library_type'].each do |attribute_name|
      structured_options[attribute_name] = structured_options[attribute_name]['value'] if contains_value_attribute?(structured_options[attribute_name])
    end
    ['to', 'from'].each do |attribute_name|
      structured_options['fragment_size_required'][attribute_name] = structured_options['fragment_size_required'][attribute_name]['value'] if structured_options['fragment_size_required'] && contains_value_attribute?(structured_options['fragment_size_required'][attribute_name])
    end

    structured_options
  end
  
  def contains_value_attribute?(request_option)
    return true if ! request_option.blank? && request_option.is_a?(Hash) && request_option['value']
    
    false
  end

  def request_options_structured=(values)
    self.request_options = NonNilHash.new.tap do |attributes|
      NonNilHash.new(:stringify_keys).deep_merge(values).tap do |json|
        attributes[:read_length]                 = json['read_length'] 
        attributes[:library_type]                = json['library_type'] 
        attributes[:fragment_size_required_from] = json['fragment_size_required', 'from'] 
        attributes[:fragment_size_required_to]   = json['fragment_size_required', 'to'] 
        attributes[:bait_library_name]           = json['bait_library']
        request_type_multiplier { |id| attributes[:multiplier, id] = json['number_of_lanes'] }
      end
    end.to_hash
  end

  def request_type_objects
    return [] if self.request_types.blank?
    ::RequestType.find(self.request_types)
  end
end
