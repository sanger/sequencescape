module Metadata
  def has_metadata(options = {}, &block)
    as_class = options.delete(:as) || self
    table_name = options.delete(:table_name) ||"#{ as_class.name.demodulize.underscore }_metadata"
    construct_metadata_class(table_name, as_class, &block)
    build_association(as_class, options)
  end

private

  def build_association(as_class, options)
    # First we build the association into the current ActiveRecord::Base class
    as_name = as_class.name.demodulize.underscore
    association_name = "#{ as_name }_metadata".underscore.to_sym
    class_name = "#{ self.name}::Metadata"

    has_one(association_name, { :class_name => class_name, :dependent => :destroy, :validate => true, :autosave => true }.merge(options).merge(:foreign_key => "#{as_name}_id", :inverse_of => :owner))
    accepts_nested_attributes_for(association_name, :update_only => true)
    named_scope :"include_#{ association_name }", { :include => association_name }

    # We now ensure that, if the metadata is not already created, that a blank instance is built.  We cannot
    # do this through the initialization of our model because we use the ActiveRecord::Base#becomes method in
    # our code, which would create a new default instance.
    class_eval <<-END_OF_INITIALIZER
      def #{association_name}_with_initialization
        #{association_name}_without_initialization || build_#{association_name}
      end
      alias_method_chain(:#{association_name}, :initialization)

      before_validation { |record| record.#{association_name } }
    END_OF_INITIALIZER

    # TODO: This should be genericised if metadata attribute grouping is extended
    class_eval <<-VALIDATING_METADATA_ATTRIBUTE_GROUPS
      def validating_ena_required_fields?
        @validating_ena_required_fields
      end

      def validating_ena_required_fields=(state)
        @validating_ena_required_fields = !!state
        self.#{ association_name }.validating_ena_required_fields = state
      end
    VALIDATING_METADATA_ATTRIBUTE_GROUPS
  end

  def construct_metadata_class(table_name, as_class, &block)
    # Build the new metadata model
    metadata = Class.new( self == as_class ? Base : as_class::Metadata)
    metadata.instance_eval(&block) if block_given?

    as_name = as_class.name.demodulize.underscore

    # Ensure that it is correctly associated back to the owner model and that the table name
    # is correctly set.
    metadata.instance_eval %Q{
      set_table_name('#{table_name}')
      belongs_to :#{as_name}, :class_name => #{ self.name.inspect }, :validate => false, :autosave => false
      belongs_to :owner, :foreign_key => :#{as_name}_id, :class_name => #{self.name.inspect}, :validate => false, :autosave => false, :inverse_of => :#{as_name}_metadata
    }

    # Finally give it a name!
    const_set(:Metadata, metadata)
  end

  class Base < ActiveRecord::Base
    # All derived classes have their own table.  We're just here to help with some behaviour
    self.abstract_class = true

    # This ensures that the default values are stored within the DB, meaning that this information will be
    # preserved for the future, unlike the original properties information which didn't store values when
    # nil which lead to us having to guess.
    def initialize(attributes = nil, &block)
      super(self.class.defaults.merge(attributes.try(:symbolize_keys) || {}), &block)
    end

    include Attributable

    def validating_ena_required_fields?
      @validating_ena_required_fields
    end

    def validating_ena_required_fields=(state)
      @validating_ena_required_fields = !!state
    end

    class << self
      extend ActiveSupport::Memoizable

      def metadata_attribute_path(field)
        self.name.underscore.split('/').map(&:to_sym) + [ field.to_sym ]
      end
      memoize :metadata_attribute_path

      def localised_sections(field)
        OpenStruct.new(
          [ :edit_info, :help, :label, :unspecified ].inject({}) do |hash,section|
            hash.tap do
              hash[ section ] = I18n.t(
                section,
                :scope => [ :metadata, metadata_attribute_path(field) ].flatten,
                :default => I18n.t(section, :scope => [ :metadata, :defaults ])
              )
            end
          end.merge(:label_options => {})
        )
      end
      memoize :localised_sections
    end
  end
end
