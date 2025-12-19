# frozen_string_literal: true

##
# Api::Messages::CommentIo is responsible for serializing and exposing
# comment-related metadata linked to PolyMetadatum records for message passing.
# This serialization serves as an interface between systems rather than for
# direct API consumption. The consumer de-serializes and morphs the message
# into a Rails model, which is later serialized into an SQL query through
# ActiveRecord abstractions.
#
# Each `PolyMetadatum` is expected to have a `metadatable_type` of `'Request'`,
# and its associated request should belong to a released batch.

# A single batch can contain multiple comments. Since the current serialization
# model does not support mapping an array of objects directly to a single resource,
# this serializer uses a nested `has_many` association to represent multiple comments
# linked to one batch.
#
# The serialized message follows this structure:
# {
#   "comment": {
#     "comments": [
#       {
#         "comment_type": "under_represented",
#         "comment_value": "true",
#         "last_updated": "2024-05-01T12:34:56Z",
#         "batch_id": 123,
#         "position": 1,
#         "tag_index": 2
#       },
#       ...
#     ]
#   }
# }
# ```
class Api::Messages::CommentIo < Api::Base
  renders_model(::Batch)

  with_nested_has_many_association(:comments, as: 'comments') do
    map_attribute_to_json_attribute(:key, 'comment_type')
    map_attribute_to_json_attribute(:value, 'comment_value')
    map_attribute_to_json_attribute(:updated_at, 'last_updated')
    map_attribute_to_json_attribute(:batch_id, 'batch_id')
    map_attribute_to_json_attribute(:position, 'position')
    map_attribute_to_json_attribute(:tag_index, 'tag_index')
  end
end
