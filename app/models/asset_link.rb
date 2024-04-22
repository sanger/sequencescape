# frozen_string_literal: true
# AssetLink is powered by acts-as-dag
# @see https://github.com/resgraph/acts-as-dag
#
# Briefly, acts-as-dag attempts to implement a directed-acyclic-graph in a
# relational database. In order to optimize for retrieval it inserts an AssetLink
# record for EACH ancestor-descendant link. As a result, it is possible to retrieve
# ALL ancestors for a given plate in a single query.
# On the flip side, this makes insert operations more expensive as the graph grows.
#
# As a result, try and avoid adding wells in to asset links, and link between Labware only.
#
# @example Example methods
#   plate.children # => [<Plate: child of plate>,<Plate: child of plate>]
#   plate.parents # => [<Plate: parent of plate>]
#   plate.descendants # => [<Plate: child of plate>,<Plate: child of plate>,<Plate: grandchild of plate>]
#   plate.ancestors # => [<Plate: parent of plate>,<Plate: grandparent of plate>]
#
# The {.children},{.parents},{.ancestors},{.descendants} methods are all Rails associations, and so can
# have further scopes applied to them
#
# @example Retrieve all ancestors of a particular purpose
#   plate.ancestors.where(purpose_id: 4)
class AssetLink < ApplicationRecord
  include Api::AssetLinkIO::Extensions
  include Uuid::Uuidable

  acts_as_dag_links node_class_name: 'Labware'
  broadcast_with_warren

  self.per_page = 500
  self.lazy_uuid_generation = true

  def destroy!; end

  module Associations
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        has_dag_links link_class_name: 'AssetLink'
        has_many :child_plates, through: :links_as_parent, source: :descendant, class_name: 'Plate'
        has_many :child_tubes, through: :links_as_parent, source: :descendant, class_name: 'Tube'
        has_many :parent_tubes, through: :links_as_child, source: :ancestor, class_name: 'Tube'
        has_many :parent_plates, through: :links_as_child, source: :ancestor, class_name: 'Plate'
      end
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_one_as_child(name, scope) # rubocop:todo Metrics/MethodLength
        plural_name = name.to_s.pluralize.to_sym
        has_many(plural_name, scope, through: :links_as_child, source: :ancestor)
        line = __LINE__ + 1
        class_eval(
          "
          def #{name}
            #{plural_name}.first
          end

          def #{name}=(value)
            raise RuntimeError, 'Value for #{name} must be saved' if value.new_record?
            old_value = self.#{name}
            parents.destroy(old_value) if old_value.present?
            AssetLink.create_edge!(value, self)
          end

          def has_#{name}?
            #{name}.present?
          end
        ",
          __FILE__,
          __LINE__ - 17
        )
      end
    end
  end
end
