# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Warren::BroadcastMessages

  # Annoyingly active record doesn't handle out of range ids when generating queries,
  # and throws an exception ActiveModel::Type::Integer
  # In a few places (particularly searches) we allow users to find by both barcode and id,
  # with barcodes falling outside of this rage.
  scope :with_safe_id, ->(query) { (-2147483648...2147483648).cover?(query.to_i) ? where(id: query.to_i) : none }
end
