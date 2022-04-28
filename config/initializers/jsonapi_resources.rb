# frozen_string_literal: true
JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :paged
  config.default_page_size = 100
  config.maximum_page_size = 500

  #:underscored_key, :camelized_key, :dasherized_key, or custom
  config.json_key_format = :underscored_key
  config.route_format = :underscored_route
end

# Disable cops as we want to match the original coding as closely as possible
# rubocop:disable all
# Monkey patch MySQL compatibility to default to no quoting:
# include_related[key][include_related]
class JSONAPI::ActiveRelationResource
  def self.sql_field_with_alias(table, field, quoted = false)
    Arel.sql("#{concat_table_field(table, field, quoted)} AS #{alias_table_field(table, field, quoted)}")
  end
end

# Monkey patch broken include processing for nested relationships
# Test coverage at: spec/requests/api/v2/wells_spec.rb
# Wells API
#   with aliquots and requests included when request is null
#     #get
#       returns a null request data attribute for aliquots
# https://github.com/cerebris/jsonapi-resources/issues/1371
# Proposed fix and PR: https://github.com/cerebris/jsonapi-resources/pull/1372
class JSONAPI::Processor
  def load_included(resource_klass, source_resource_id_tree, include_related, options)
    source_rids = source_resource_id_tree.fragments.keys

    include_related.try(:each_key) do |key|
      relationship = resource_klass._relationship(key)
      relationship_name = relationship.name.to_sym

      find_related_resource_options = options.except(:filters, :sort_criteria, :paginator)
      find_related_resource_options[:sort_criteria] = relationship.resource_klass.default_sort
      find_related_resource_options[:cache] = resource_klass.caching?

      related_fragments =
        resource_klass.find_included_fragments(source_rids, relationship_name, find_related_resource_options)

      related_resource_id_tree = source_resource_id_tree.fetch_related_resource_id_tree(relationship)

      ### CHANGED BIT
      # v0.10.5 mistakenly uses the local variable `include_related` in
      # place of the symbol in the last argument. This means we fail
      # to pass through the included relationships, and incorrectly
      # initialize the nested resource fragments. As a result, empty
      # relationships are incorrectly populated.
      related_resource_id_tree.add_resource_fragments(related_fragments, include_related[key][:include_related])

      ### CHANGED BIT

      # Now recursively get the related resources for the currently found resources
      load_included(
        relationship.resource_klass,
        related_resource_id_tree,
        include_related[relationship_name][:include_related],
        options
      )
    end
  end
end
# rubocop:enable
