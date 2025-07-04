# frozen_string_literal: true

module Metadata
  # @!macro [attach] has_metadata
  #   @!parse class Metadata < Metadata::Base; end
  def has_metadata(options = {}, &)
    as_class = options.delete(:as) || self
    table_name = options.delete(:table_name) || "#{as_class.name.demodulize.underscore}_metadata"
    construct_metadata_class(table_name, as_class, &)
    build_association(as_class, options)
  end

  SECTION_FIELDS = %i[edit_info help label unspecified].freeze
  Section = Struct.new(*SECTION_FIELDS, :label_options)

  private

  def build_association(as_class, options) # rubocop:todo Metrics/MethodLength
    # First we build the association into the current ActiveRecord::Base class
    as_name = as_class.name.demodulize.underscore
    association_name = "#{as_name}_metadata".underscore.to_sym
    class_name = "#{name}::Metadata"

    default_options = {
      class_name: class_name,
      dependent: :destroy,
      validate: true,
      autosave: true,
      inverse_of: :owner,
      foreign_key: "#{as_name}_id"
    }
    has_one association_name, **default_options, **options # rubocop:todo Rails/HasManyOrHasOneDependent
    accepts_nested_attributes_for(association_name, update_only: true)

    unless respond_to?(:"include_#{association_name}")
      scope :"include_#{association_name}", lambda { includes(association_name) }
    end

    # We now ensure that, if the metadata is not already created, that a blank instance is built.  We cannot
    # do this through the initialization of our model because we use the ActiveRecord::Base#becomes method in
    # our code, which would create a new default instance.
    # If lazy metadata is true we do NOT generate metadata upfront. This is the case for internal requests,
    # where metadata is unused anyway.
    line = __LINE__ + 1
    class_eval(
      "
      class_attribute :lazy_metadata
      self.lazy_metadata = false

      def #{association_name}
        super ||
        build_#{association_name}
      end

      def tags
        self.class.tags.select{|tag| tag.for?(accession_service.provider)}
      end

      def self.tags
        @tags ||= []
      end

      before_validation :#{association_name}, on: :create, unless: :lazy_metadata?

    ",
      __FILE__,
      line
    )
  end

  def include_tag(tag, options = {})
    tags << AccessionedTag.new(tag, options[:as], options[:services], options[:downcase])
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

  def construct_metadata_class(table_name, as_class, &)
    parent_class = self == as_class ? Metadata::Base : as_class::Metadata
    metadata = Class.new(parent_class, &)

    as_name = as_class.name.demodulize.underscore

    # Ensure that it is correctly associated back to the owner model and that the table name
    # is correctly set.
    metadata.table_name = table_name
    metadata.belongs_to :"#{as_name}", class_name: name, validate: false, autosave: false
    metadata.belongs_to :owner,
                        foreign_key: :"#{as_name}_id",
                        class_name: name,
                        validate: false,
                        autosave: false,
                        inverse_of: :"#{as_name}_metadata",
                        touch: true

    # Finally give it a name!
    const_set(:Metadata, metadata)
  end

  class Base < ApplicationRecord
    # All derived classes have their own table.  We're just here to help with some behaviour
    self.abstract_class = true

    # This ensures that the default values are stored within the DB, meaning that this information will be
    # preserved for the future, unlike the original properties information which didn't store values when
    # nil which lead to us having to guess.
    def initialize(attributes = {}, *, &)
      super(self.class.defaults.merge(attributes.try(:symbolize_keys) || {}), *, &)
    end

    before_validation :merge_instance_defaults, on: :create

    def merge_instance_defaults
      # Replace attributes with the default if the value is nil
      instance_defaults.each do |attribute, value|
        next unless send(attribute).nil?

        send(:"#{attribute}=", value)
      end
    end

    include Attributable

    delegate :validator_for, to: :owner

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
          *(
            SECTION_FIELDS.map do |section|
              I18n.t(
                section,
                scope: [:metadata, metadata_attribute_path(field)].flatten,
                default: I18n.t(section, scope: %i[metadata defaults])
              )
            end << {}
          )
        )
      end

      def localised_sections(field)
        localised_sections_store[field]
      end
    end
  end
end
