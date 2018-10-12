class AssetLink < ApplicationRecord
  include Api::AssetLinkIO::Extensions
  include Uuid::Uuidable

  acts_as_dag_links node_class_name: 'Asset'
  broadcast_via_warren

  self.per_page = 500
  self.lazy_uuid_generation = true

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
