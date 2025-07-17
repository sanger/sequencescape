# frozen_string_literal: true

# Basic base class for all ActiveRecord::Base records in Sequencescape
# @see https://www.rubydoc.info/github/RailsApps/learn-rails/master/ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # include Warren::BroadcastMessages
  include Warren::Callback

  # Provides {Squishify} which allows attributes to automatically have their whitespace compressed before validation
  # @example Squishifying a study title
  #  class Study < ApplicationRecord
  #    squishify :title
  #  end
  #
  #  study = Study.new(title: 'Double  spaces  are    not cool')
  #  study.valid? # => true
  #  study.title # => "Double spaces are not cool"
  extend Squishify

  # Annoyingly active record doesn't handle out of range ids when generating queries,
  # and throws an exception ActiveModel::Type::Integer
  # In a few places (particularly searches) we allow users to find by both barcode and id,
  # with barcodes falling outside of this rage.
  scope :with_safe_id, ->(query) { (-2_147_483_648...2_147_483_648).cover?(query.to_i) ? where(id: query.to_i) : none }
  scope :where_is_a, ->(clazz) { where(sti_type: [clazz, *clazz.descendants].map(&:name)) }
  scope :select_table, -> { select("#{table_name}.*") }

  # Moved here from BulkSubmission where it modified ActiveRecord::Base
  # At time of move only used on Study, Project and AssetGroup
  class << self
    def find_by_id_or_name!(id, name)
      find_by_id_or_name(id, name) || raise(ActiveRecord::RecordNotFound, "Could not find #{self.name}: #{id || name}")
    end

    def find_by_id_or_name(id, name)
      return find(id) if id.present?
      raise StandardError, "Must specify #{self.name.downcase} ID or name" if name.blank?

      find_by(name:)
    end

    # Temporary compatibility layer following AssetRefactor:
    # will allow labware to get passed into associations expecting
    # receptacles where there is no ambiguity. (e.g. tubes)
    # @example
    #   convert_labware_to_receptacle_for :library
    #   def library=(library)
    #     return super if library.is_a?(Receptacle)
    #     Rails.logger.warn("#{library.class.name} passed to library")
    #     super(library.receptacle)
    #   end
    def convert_labware_to_receptacle_for(*associations)
      associations.each do |assn|
        define_method(:"#{assn}=") do |associated|
          return super(associated) if associated.is_a?(Receptacle)

          Rails.logger.warn("#{associated.class.name} passed to #{assn}")
          super(associated&.receptacle)
        end
      end
    end
  end

  # Defining alias_association to provide an alias for an association (instead of an attribute)
  # @example
  #   alias_association :labware, :receptacle
  #   def labware=(labware)
  #     return super if labware.is_a?(Receptacle)
  #     super(labware.receptacle)
  #   end
  # @param [Symbol] new_name The new name of the association
  # @param [Symbol] old_name The old name of the association (the one that already exists on the model
  def self.alias_association(new_name, old_name)
    # Define the getter
    define_method(new_name) { send(old_name) }

    # Define the setter
    define_method(:"#{new_name}=") { |new_value| send(:"#{old_name}=", new_value) }
  end
end
