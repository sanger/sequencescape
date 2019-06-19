# JG: This is a bit speculative, as all this happened before my time but it matches
# what I can see in the database. Studies were also marked as being identifiable,
# but it doesn't appear that this functionality was used.
# Table used to track original identifiers of {Sample} and {Asset} and {Study} imported from
# external databases, although only ever appears to have been used for the initial import
# from SNP.
# The table remains for reference purposes but shouldn't be involved in any active behaviour
class Identifier < ApplicationRecord
  validates_presence_of :resource_name, :identifiable_id
  validates_uniqueness_of :external_id, scope: [:identifiable_id, :resource_name] # only one external per asset per resource

  belongs_to :identifiable, polymorphic: true
  belongs_to :external, polymorphic: true
end
