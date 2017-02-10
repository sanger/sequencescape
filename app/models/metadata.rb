# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require_dependency 'attributable'

module Metadata
  def has_metadata(options = {}, &block)
    as_class = options.delete(:as) || self
    table_name = options.delete(:table_name) || "#{as_class.name.demodulize.underscore}_metadata"
    construct_metadata_class(table_name, as_class, &block)
    build_association(as_class, options)
  end

  SECTION_FIELDS = [:edit_info, :help, :label, :unspecified]
  Section = Struct.new(*SECTION_FIELDS, :label_options)

private

  def build_association(as_class, options)
    # First we build the association into the current ActiveRecord::Base class
    as_name = as_class.name.demodulize.underscore
    association_name = "#{as_name}_metadata".underscore.to_sym
    class_name = "#{name}::Metadata"

    has_one(association_name, { class_name: class_name, dependent: :destroy, validate: true, autosave: true, inverse_of: :owner }.merge(options).merge(foreign_key: "#{as_name}_id", inverse_of: :owner))
    accepts_nested_attributes_for(association_name, update_only: true)
    scope :"include_#{ association_name }", -> { includes(association_name) }

    # We now ensure that, if the metadata is not already created, that a blank instance is built.  We cannot
    # do this through the initialization of our model because we use the ActiveRecord::Base#becomes method in
    # our code, which would create a new default instance.
    line = __LINE__ + 1
    class_eval("

      def #{association_name}_with_initialization
        #{association_name}_without_initialization ||
        build_#{association_name}
      end

      alias_method_chain(:#{association_name}, :initialization)

      def validating_ena_required_fields=(state)
        @validating_ena_required_fields = !!state
        self.#{association_name}.validating_ena_required_fields = state
      end

      def validating_ena_required_fields?
        @validating_ena_required_fields
      end

      def tags
        self.class.tags.select{|tag| tag.for?(accession_service.provider)}
      end

      def required_tags
        self.class.required_tags[accession_service.try(:provider)]+self.class.required_tags[:all]
      end

      def self.tags
        @tags ||= []
      end

      before_validation { |record| record.#{association_name} }

    ", __FILE__, line)

    def self.required_tags
      @required_tags ||= Hash.new { |h, k| h[k] = Array.new }
    end
  end

  def include_tag(tag, options = Hash.new)
    tags << AccessionedTag.new(tag, options[:as], options[:services], options[:downcase])
  end

  def require_tag(tag, services = :all)
    [services].flatten.each do |service|
      required_tags[service] << tag
    end
  end

  class AccessionedTag
    attr_reader :tag, :name, :downcase
    def initialize(tag, as = nil, services = [], downcase = false)
      @tag = tag
      @name = as || tag
      @services = [services].flatten.compact
      @downcase = downcase
    end

    def for?(service)
      @services.empty? || @services.include?(service)
    end
  end

  def construct_metadata_class(table_name, as_class, &block)
    metadata = Class.new(self == as_class ? Base : as_class::Metadata)
    metadata.instance_eval(&block) if block_given?

    as_name = as_class.name.demodulize.underscore

    # Ensure that it is correctly associated back to the owner model and that the table name
    # is correctly set.
    metadata.instance_eval "
      self.table_name =('#{table_name}')
      belongs_to :#{as_name}, :class_name => #{name.inspect}, :validate => false, :autosave => false
      belongs_to :owner, :foreign_key => :#{as_name}_id, :class_name => #{name.inspect}, :validate => false, :autosave => false, :inverse_of => :#{as_name}_metadata
    "

    # Finally give it a name!
    const_set(:Metadata, metadata)
  end

  class Base < ActiveRecord::Base
    # All derived classes have their own table.  We're just here to help with some behaviour
    self.abstract_class = true

    # This ensures that the default values are stored within the DB, meaning that this information will be
    # preserved for the future, unlike the original properties information which didn't store values when
    # nil which lead to us having to guess.
    def initialize(attributes = {}, *args, &block)
      super(self.class.defaults.merge(attributes.try(:symbolize_keys) || {}), *args, &block)
    end

    before_validation :merge_instance_defaults, on: :create

    def merge_instance_defaults
      # Replace attributes with the default if the value is nil
      self.attributes = instance_defaults.merge(attributes.symbolize_keys) { |_key, default, attribute| attribute.nil? ? default : attribute }
    end

    include Attributable

    def validating_ena_required_fields?
      @validating_ena_required_fields ||= false
    end

    def validating_ena_required_fields=(state)
      @validating_ena_required_fields = !!state
    end

    delegate :validator_for, to: :owner

    def service_specific_fields
      owner.required_tags.uniq.select do |tag|
        owner.errors.add(:base, "#{tag} is required") if send(tag).blank?
      end.empty?
    end

    class << self
      def metadata_attribute_path_store
        @md_a_p ||= Hash.new { |h, field| h[field] = metadata_attribute_path_generator(field) }
      end

      def metadata_attribute_path_generator(field)
        name.underscore.split('/').map(&:to_sym) + [field.to_sym]
      end

      def metadata_attribute_path(field)
        metadata_attribute_path_store[field]
      end

      def localised_sections_store
        @loc_sec ||= Hash.new { |h, field| h[field] = localised_sections_generator(field) }
      end

      def localised_sections_generator(field)
        Section.new(
          * (SECTION_FIELDS.map do |section|
            I18n.t(
              section,
              scope: [:metadata, metadata_attribute_path(field)].flatten,
              default: I18n.t(section, scope: [:metadata, :defaults])
            )
          end << {})
        )
      end

      def localised_sections(field)
        localised_sections_store[field]
      end
    end
  end
end
