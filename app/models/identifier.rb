# frozen_string_literal: true
# JG: This is a bit speculative, as all this happened before my time but it matches
# what I can see in the database. Studies were also marked as being identifiable,
# but it doesn't appear that this functionality was used.
# Table used to track original identifiers of {Sample} and {Asset} and {Study} imported from
# external databases, although only ever appears to have been used for the initial import
# from SNP.
# The table remains for reference purposes but shouldn't be involved in any active behaviour
class Identifier < ApplicationRecord
  validates :resource_name, :identifiable_id, presence: true

  # rubocop:todo Layout/LineLength
  validates :external_id, uniqueness: { scope: %i[identifiable_id resource_name] } # only one external per asset per resource

  # rubocop:enable Layout/LineLength

  belongs_to :identifiable, polymorphic: true
  belongs_to :external, polymorphic: true
end
