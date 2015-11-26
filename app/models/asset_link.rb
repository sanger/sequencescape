#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.

class AssetLink < ActiveRecord::Base
  include Api::AssetLinkIO::Extensions

  acts_as_dag_links :node_class_name => 'Asset'

  # Enables the bulk creation of the asset links defined by the pairs passed as edges.
  # Basically we should be moving away from these and this enables us to ignore them.
  class BuilderJob < Struct.new(:links)
    def perform
      ActiveRecord::Base.transaction do
        links.map { |parent,child| AssetLink.create!(:ancestor_id => parent, :descendant_id => child) }
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
      super(children.map { |child| [parent.id,child.id] })
    end
  end

  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  def destroy!
  end

  module Associations
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        has_dag_links :link_class_name => 'AssetLink'
      end
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_one_as_child(name, options = {})
        # has_one(name, options.merge(:through => :links_as_child, :source => :ancestor))

        line = __LINE__ + 1
        class_eval(%Q{

          def #{name}
            ancestors.find(:first,#{options.inspect})
          end

          def #{name}=(value)
            raise RuntimeError, 'Value for #{name} must be saved' if value.new_record?
            old_value = self.#{name}
            parents.delete(old_value) if old_value.present?
            AssetLink.create_edge!(value, self)
          end

          def has_#{name}?
            #{name}.present?
          end
        }, __FILE__, line)
      end
    end
  end
end
