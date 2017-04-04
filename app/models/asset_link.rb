# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class AssetLink < ActiveRecord::Base
  include Api::AssetLinkIO::Extensions

  acts_as_dag_links node_class_name: 'Asset'

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
