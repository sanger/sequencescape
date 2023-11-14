# # frozen_string_literal: true

# # JSON API resource assumes that single table inheritance uses the default
# # inheritance column, type. This looks like it may be fixed in 0.10.0
# # This monkey patches the corresponding method to retrieve the type
# # column directly.

# # Tested in spec/requests/plates_spec.rb (Where we actually depend on this behaviour)

# require 'jsonapi-resources'

# unless JSONAPI::Resources::VERSION == '0.9.0'
#   # We're being naughty. So lets ensure that anyone can easily find
#   # our little hacks.
#   Rails.logger.warn '*' * 80
#   Rails.logger.warn "We are monkey patching 'jsonapi-resources' in #{__FILE__} " \
#                       'but the gem version has changed since the patch was written.' \
#                       'Please ensure that the patch is still required and compatible.'
#   Rails.logger.warn '*' * 80
# end

# # Modified from: jsonapi-resources-0.9.0/lib/jsonapi/resource_serializer.rb
# module JSONAPI
#   # Disable cops to prevent auto-correct-induced drift
#   # rubocop:disable all
#   # Reopen ResourceSerializer to fix the polymorphic associations
#   class ResourceSerializer
#     def to_many_linkage(source, relationship)
#       linkage = []

#       linkage_types_and_values =
#         if source.preloaded_fragments.key?(format_key(relationship.name))
#           source.preloaded_fragments[format_key(relationship.name)].map do |_, resource|
#             [relationship.type, resource.id]
#           end
#         elsif relationship.polymorphic?
#           assoc = source._model.public_send(relationship.name)

#           # Avoid hitting the database again for values already pre-loaded
#           # MODIFICATION BEGINS
#           if assoc.respond_to?(:loaded?) && assoc.loaded?
#             assoc.map { |obj| [source.class.resource_type_for(obj)&.pluralize, obj.id] }
#           else
#             type_column = assoc.inheritance_column
#             assoc
#               .pluck(type_column, :id)
#               .map do |type, id|
#                 [source.class._model_hints[type.underscore]&.pluralize || type.underscore.pluralize, id]
#               end
#           end
#           # MODIFICATION ENDS
#         else
#           source.public_send(relationship.name).map { |value| [relationship.type, value.id] }
#         end

#       linkage_types_and_values.each do |type, value|
#         linkage.append(type: format_key(type), id: @id_formatter.format(value)) if type && value
#       end
#       linkage
#     end

#     def foreign_key_types_and_values(source, relationship)
#       if relationship.is_a?(JSONAPI::Relationship::ToMany)
#         if relationship.polymorphic?
#           assoc = source._model.public_send(relationship.name)

#           # Avoid hitting the database again for values already pre-loaded
#           # MODIFICATION BEGINS
#           if assoc.respond_to?(:loaded?) && assoc.loaded?
#             assoc.map { |obj| [source.class.resource_type_for(obj), @id_formatter.format(obj.id)] }
#           else
#             type_column = assoc.inheritance_column
#             assoc
#               .pluck(type_column, :id)
#               .map do |type, id|
#                 [
#                   source.class._model_hints[type.underscore]&.pluralize || type.underscore.pluralize,
#                   @id_formatter.format(id)
#                 ]
#               end
#             # MODIFICATION ENDS
#           end
#         else
#           source.public_send(relationship.name).map { |value| [relationship.type, @id_formatter.format(value.id)] }
#         end
#       end
#     end
#     # rubocop:enable all
#   end
# end


# Fix: "labware"."id" AS "labware_id" not valid quoting for mysql.
# TODO: JSON API RESOURCES Version 11 should solve it <https://github.com/cerebris/jsonapi-resources/issues/1369>
class JSONAPI::ActiveRelationResource
  def self.sql_field_with_alias(table, field, quoted = false)
    Arel.sql("#{concat_table_field(table, field, quoted)} AS #{alias_table_field(table, field, quoted)}")
  end
end

class JSONAPI::ResourceController
  # Caution: Using this approach for a 'create' action is not strictly JSON API
  # compliant.
  def serialize_array(array)
    {
      data: array.map do |r|
        JSONAPI::ResourceSerializer.new(r.class).object_hash(r, {})
      end
    }
  end

  # Where possible try to use the default json api resources actions, as
  # they will correctly ensure parameters such as include are properly processed
  def serialize_resource(resource)
    { data: JSONAPI::ResourceSerializer.new(resource.class).object_hash(resource, {}) }
  end
end

class JSONAPI::ResourceSerializer
  def serialize_to_hash(resource)
    { data: object_hash(resource, {}) }
  end
end