# frozen_string_literal: true

module SequencescapeExcel
  module Helpers
    ##
    # Just a little bit of extra help to add ActiveModel::Model.
    # Attribute accessors and default attributes can be created.
    module Attributes
      extend ActiveSupport::Concern
      include ActiveModel::Model
      include ActiveRecord::AttributeAssignment
      include Comparable

      ##
      # ClassMethods
      module ClassMethods
        def setup_attributes(*attributes)
          options = attributes.extract_options!

          attr_accessor(*attributes)

          define_method :attributes do
            attributes
          end

          define_method :default_attributes do
            options[:defaults] || {}
          end
        end
      end

      ##
      # Push all of the instance variables onto an array useful for comparison.
      def to_a
        attributes.filter_map { |v| instance_variable_get(:"@#{v}") }
      end

      ##
      # Two objects are comparable if all of their instance variables that are present
      # are comparable.
      def <=>(other)
        return unless other.is_a?(self.class)

        to_a <=> other.to_a
      end
    end
  end
end
