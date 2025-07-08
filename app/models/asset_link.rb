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
  include Api::AssetLinkIo::Extensions
  include Uuid::Uuidable

  acts_as_dag_links node_class_name: 'Labware'
  broadcast_with_warren

  self.per_page = 500
  self.lazy_uuid_generation = true

  def destroy!
  end

  module Associations
    # rubocop:disable Metrics/MethodLength
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        has_dag_links link_class_name: 'AssetLink'
        has_many :child_tubes, through: :links_as_parent, source: :descendant, class_name: 'Tube'
        has_many :child_plates, through: :links_as_parent, source: :descendant, class_name: 'Plate'
        has_many :child_tube_racks, through: :links_as_parent, source: :descendant, class_name: 'TubeRack'
        has_many :parent_tubes, through: :links_as_child, source: :ancestor, class_name: 'Tube'
        has_many :parent_plates, through: :links_as_child, source: :ancestor, class_name: 'Plate'
        has_many :parent_tube_racks, through: :links_as_child, source: :ancestor, class_name: 'TubeRack'
      end
      base.extend(ClassMethods)
    end

    # rubocop:enable Metrics/MethodLength

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
          line
        )
      end
    end
  end

  # Creates an edge between the ancestor and descendant nodes using save.
  #
  # This method first attempts to find an existing link between the ancestor
  # and descendant. If no link is found, it builds a new edge and saves it.
  # If a link is found, it makes the link an edge and saves it.
  #
  # This method is overridden to handle race conditions in finding an
  # existing link and has_duplicates validation. It also assumes that there
  # is a unique-together index on ancestor_id and descendant_id columns.
  #
  # @param ancestor [Dag::Standard::EndPoint] The ancestor node.
  # @param descendant [Dag::Standard::EndPoint] The descendant node.
  # @return [Boolean] Returns true if the edge is successfully created or
  #   already exists, false otherwise.
  # @raise [ActiveRecord::RecordNotUnique] Re-raises any exception if it is
  #   not a constraint violation that involves ancestor_id and descendant_id
  #   columns.
  def self.create_edge(ancestor, descendant)
    # Two processes try to find an existing link.
    link = find_link(ancestor, descendant)
    # Either or both may find no link and try to create a new edge.
    if link.nil?
      edge = build_edge(ancestor, descendant)
      result = save_edge_or_handle_error(edge)
      return result unless result.nil? # Bubble up.

      # Losing process finds the edge created by the winning process.
      link = find_link(ancestor, descendant)
    end

    return if link.nil?

    link.make_direct
    link.changed? ? link.save : true
  end

  # Saves the edge between the ancestor and descendant nodes or handles errors.
  #
  # @param edge [AssetLink] The edge object containing the errors.
  # @return [Boolean] Returns true if the edge is successfully saved,
  #   nil if the error is unique validation or constraint violation,
  #   false if the error is another validation error.
  # @raise [ActiveRecord::RecordNotUnique] Re-raises an exception if the
  #   exception caught is not a unique constraint violation.
  def self.save_edge_or_handle_error(edge)
    # Winning process successfully saves the edge (direct link).
    return true if edge.save
    # has_duplicate validation may see it for the losing process before
    # hitting the DB.
    return false unless unique_validation_error?(edge) # Bubble up.

    edge.errors.clear # Clear all errors and use the existing link.
  rescue ActiveRecord::RecordNotUnique => e
    # Unique constraint violation is triggered for the losing process after
    # hitting the DB.
    raise unless unique_violation_error?(edge, e) # Bubble up.
  end

  # Checks if the validation error includes a specific message indicating a
  # unique link already exists.
  #
  # @param edge [AssetLink] The edge object containing the errors.
  # @return [Boolean] Returns true if the errors include the message "Link
  #   already exists between these points", false otherwise.
  def self.unique_validation_error?(edge)
    edge.errors[:base].include?('Link already exists between these points')
  end

  # Checks if the unique constraint violation involves the specified columns.
  #
  # @param edge [AssetLink] The edge object containing the column names.
  # @param exception [ActiveRecord::RecordNotUnique] The exception raised due
  #   to the unique constraint violation.
  # @return [Boolean] Returns true if the exception message includes both the
  #   ancestor and descendant column names, false otherwise.
  def self.unique_violation_error?(edge, exception)
    [edge.ancestor_id_column_name, edge.descendant_id_column_name].all? { |col| exception.message.include?(col) }
  end
end
