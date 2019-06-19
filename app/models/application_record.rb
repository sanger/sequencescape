# frozen_string_literal: true

# Basic base class for all ActiveRecord::Base records in Sequencescape
# @see https://www.rubydoc.info/github/RailsApps/learn-rails/master/ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Warren::BroadcastMessages

  # Annoyingly active record doesn't handle out of range ids when generating queries,
  # and throws an exception ActiveModel::Type::Integer
  # In a few places (particularly searches) we allow users to find by both barcode and id,
  # with barcodes falling outside of this rage.
  scope :with_safe_id, ->(query) { (-2147483648...2147483648).cover?(query.to_i) ? where(id: query.to_i) : none }
  scope :where_is_a?, ->(clazz) { where(sti_type: [clazz, *clazz.descendants].map(&:name)) }

  # Moved here from BulkSubmission where it modified ActiveRecord::Base
  # At time of move only used on Study, Project and AssetGroup
  class << self
    def find_by_id_or_name!(id, name)
      find_by_id_or_name(id, name) || raise(ActiveRecord::RecordNotFound, "Could not find #{self.name}: #{id || name}")
    end

    def find_by_id_or_name(id, name)
      return find(id) if id.present?
      raise StandardError, 'Must specify at least ID or name' if name.blank?

      find_by(name: name)
    end
  end
end
