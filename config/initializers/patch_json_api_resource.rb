# frozen_string_literal: true

# JSON API resource assumes that single table inheritance uses the default
# inheritance column, type. This looks like it may be fixed in 0.10.0
# This monkey patches the corresponding method to retrieve the type
# column directly.

# Tested in spec/requests/plates_spec.rb (Where we actually depend on this behaviour)

require 'jsonapi-resources'

unless JSONAPI::Resources::VERSION == '0.9.5'
  # We're being naughty. So lets ensure that anyone can easily find
  # our little hacks.
  Rails.logger.warn '*' * 80
  Rails.logger.warn "We are monkey patching 'jsonapi-resources' in #{__FILE__} "\
                    'but the gem version has changed since the patch was written.'\
                    'Please ensure that the patch is still required and compatible.'
  Rails.logger.warn '*' * 80
end

# Modified from: jsonapi-resources-0.9.5/lib/jsonapi/resource_serializer.rb
module JSONAPI
  # Disable cops to prevent auto-correct-induced drift
  # rubocop:disable all
  # Reopen ResourceSerializer to fix the polymorphic associations
  class ResourceSerializer
    def to_many_linkage(source, relationship)
      linkage = []

      linkage_types_and_values = if source.preloaded_fragments.key?(format_key(relationship.name))
         source.preloaded_fragments[format_key(relationship.name)].map do |_, resource|
           [relationship.type, resource.id]
         end
       elsif relationship.polymorphic?
         assoc = source._model.public_send(relationship.name)
         # Avoid hitting the database again for values already pre-loaded
         # MODIFICATION BEGINS
         if assoc.respond_to?(:loaded?) and assoc.loaded?
           assoc.map do |obj|
             [source.class.resource_type_for(obj)&.pluralize, obj.id]
           end
         else
           type_column = assoc.inheritance_column
           assoc.pluck(type_column, :id).map do |type, id|
             [source.class._model_hints[type.underscore]&.pluralize || type.underscore.pluralize, id]
           end
         end
         # MODIFICATION ENDS
      else
        include_config = include_directives.include_config(relationship.name.to_sym) if include_directives
        include_filters = include_config[:include_filters] if include_config
        options = { filters: include_filters || {} }
        source.public_send(relationship.name, options).map do |value|
          [relationship.type, value.id]
        end
      end

      linkage_types_and_values.each do |type, value|
        if type && value
          linkage.append({type: format_key(type), id: @id_formatter.format(value)})
        end
      end
      linkage
    end

    def foreign_key_types_and_values(source, relationship)
      if relationship.is_a?(JSONAPI::Relationship::ToMany)
        if relationship.polymorphic?
          assoc = source._model.public_send(relationship.name)
          # Avoid hitting the database again for values already pre-loaded
          # MODIFICATION BEGINS
          if assoc.respond_to?(:loaded?) and assoc.loaded?
            assoc.map do |obj|
              [source.class.resource_type_for(obj), @id_formatter.format(obj.id)]
            end
          else
            type_column = assoc.inheritance_column
            assoc.pluck(type_column, :id).map do |type, id|
              [source.class._model_hints[type.underscore]&.pluralize || type.underscore.pluralize, @id_formatter.format(id)]
            end
            # MODIFICATION ENDS
          end
        else
          source.public_send(relationship.name).map do |value|
            [relationship.type, @id_formatter.format(value.id)]
          end
        end
      end
    end
    # rubocop:enable all
  end
end
