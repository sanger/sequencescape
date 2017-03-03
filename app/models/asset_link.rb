# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class AssetLink < ActiveRecord::Base
  include Api::AssetLinkIO::Extensions

  acts_as_dag_links node_class_name: 'Asset'

  # Enables the bulk creation of the asset links defined by the pairs passed as edges.
  class BuilderJob < Struct.new(:links)
    # For memory resons we need to limit transaction size to 10 links at a time
    TRANSACTION_COUNT = 10
    def perform
      links.each_slice(TRANSACTION_COUNT) do |link_group|
        ActiveRecord::Base.transaction do
          link_group.each do |parent, child|
            # Create edge can accept either a model (which it converts to an endpoint) or
            # an endpoint itself. Using the endpoints directly we avoid the unnecessary
            # database calls, but more importantly avoid the need to instantiate a load of
            # active record objects.
            parent_endpoint = Dag::Standard::EndPoint.new(parent)
            child_endpoint  = Dag::Standard::EndPoint.new(child)
            AssetLink.create_edge(parent_endpoint, child_endpoint)
          end
        end
      end
    end

    def self.create(*args)
      Delayed::Job.enqueue(new(*args))
    end
  end

  # Convenient mechanism for queueing the creation of AssetLink instances where there is
  # singular parent with lots of children.
  class Job < BuilderJob
    def initialize(parent, children)
      super(children.map { |child| [parent.id, child.id] })
    end
  end

  self.per_page = 500
  include Uuid::Uuidable

  def destroy!
  end

  module Associations
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        has_dag_links link_class_name: 'AssetLink'
      end
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_one_as_child(name, scope)
        plural_name = name.to_s.pluralize.to_sym
        has_many(plural_name, scope, through: :links_as_child, source: :ancestor)
        line = __LINE__ + 1
        class_eval("
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
        ", __FILE__, line)
      end
    end
  end
end
