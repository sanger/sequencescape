class AssetLink < ActiveRecord::Base
  include Api::AssetLinkIO::Extensions

  # Convenient mechanism for queueing the creation of AssetLink instances for asynchronous processing.
  # Basically we should be moving away from these and this enables us to ignore them.
  class Job < Struct.new(:parent, :children)
    def self.create(parent, children)
      Delayed::Job.enqueue(new(parent.id, children.map(&:id)))
    end

    def perform
      children.map { |child| AssetLink.create!(:ancestor_id => parent, :descendant_id => child) }
    end
  end

  cattr_reader :per_page
  @@per_page = 500
  acts_as_dag_links :node_class_name => 'Asset'
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
        has_one(name, options.merge(:through => :links_as_child, :source => :ancestor))

        line = __LINE__ + 1
        class_eval(%Q{
          def #{name}=(value)
            raise RuntimeError, 'Value for #{name} must be saved' if value.new_record?
            old_value = self.#{name}
            parents.delete(old_value) if old_value.present?
            AssetLink.create_edge(value, self)
          end

          def has_#{name}?
            #{name}.present?
          end
        }, __FILE__, line)
      end
    end
  end
end
