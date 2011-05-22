class AssetLink < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 500
  acts_as_dag_links :node_class_name => 'Asset'
  include Uuid::Uuidable
  
  named_scope :including_associations_for_json, { :include => [:uuid_object, { :ancestor => :uuid_object }, { :descendant  => :uuid_object }] }

  def self.render_class
    Api::AssetLinkIO
  end

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
