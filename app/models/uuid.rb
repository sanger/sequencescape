# frozen_string_literal: true
# Stores the uuids of all out records, associated via a polymorphic association
# Allows the {file:docs/api_v1 V1 API} to find any record from just a uuid
class Uuid < ApplicationRecord
  # Allows tests to dictate the next UUID generted for a given class
  class_attribute :store_for_tests

  module Uuidable
    def self.included(base)
      base.class_eval do
        # Lazy uuid generation disables uuid generation on record creation. For the most part this is
        # undesireable (see below) but is useful for aliquots, as we do not expose the uuids via the API
        # and only require them asynchronously.
        class_attribute :lazy_uuid_generation
        self.lazy_uuid_generation = false

        # Ensure that the resource has a UUID and that it's always created when the instance is created.
        # It seems better not to do this but the performance of the API is directly affected by having to
        # create these instances when they do not exist.
        has_one :uuid_object, class_name: 'Uuid', as: :resource, dependent: :destroy, inverse_of: :resource
        after_create :ensure_uuid_created, unless: :lazy_uuid_generation?

        # Some named scopes ...
        scope :include_uuid, -> { includes(:uuid_object) }
        scope :with_uuid, ->(uuid) { joins(:uuid_object).where(uuids: { external_id: uuid }) }
      end
    end

    # In the test environment we need to have a slightly different behaviour, as we can predefine
    # the UUID for a record to make things predictable.  In production new records always have new
    # UUIDs.
    if %w[test cucumber].include?(Rails.env)
      def ensure_uuid_created
        new_uuid = Uuid.store_for_tests && Uuid.store_for_tests.next_uuid_for(self.class.base_class)
        create_uuid_object!(resource: self, external_id: new_uuid)
      end
    else
      def ensure_uuid_created
        create_uuid_object!(resource: self) || raise(ActiveRecord::RecordInvalid) # = Uuid.create!(:resource => self)
      end
    end
    private :ensure_uuid_created

    # Marks a record as being unsaved and hence the UUID is not present.  This is not something we
    # want to actually happen without being explicitly told; hence, the 'uuid' method below will
    # error if the record is unsaved as that's exactly what should happen.
    #
    # It also means that marking a record by calling this method, and then attempting to save it,
    # will result in another validation exception.  Again, exactly what we want.
    def unsaved_uuid!
      self.uuid_object = Uuid.new(external_id: nil)
    end

    #--
    # You cannot give a UUID to something that hasn't been saved, which means that the UUID can't be
    # relied on to actually be present, nor can it be relied on to be output into any JSON in the API.
    #++
    def uuid
      (uuid_object || create_uuid_object).uuid
    end
  end

  VALID_REGEXP = /\A[\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12}\z/
  validates :external_id, format: { with: VALID_REGEXP }

  # It is more efficient to check the individual parts of the resource association than it is to check the
  # association itself as the latter causes the record to be reloaded
  belongs_to :resource, polymorphic: true, inverse_of: :uuid_object

  # TODO[xxx]: remove this and use resource everywhere!
  def object
    resource
  end

  scope :with_resource_type, ->(type) { where(resource_type: type.to_s) }

  scope :include_resource, -> { includes(:resource) }
  scope :with_external_id, ->(external_id) { where(external_id:) }
  scope :with_resource_by_type_and_id, ->(t, id) { where(resource_type: t, resource_id: id) }

  # Limits the query to resources of the given type if provided. Otherwise returns all
  scope :limited_to_resource, ->(resource_type) { resource_type.nil? ? all : where(resource_type:) }

  before_validation do |record|
    record.external_id = Uuid.generate_uuid if record.new_record? && record.external_id.blank?
  end

  def uuid
    external_id
  end

  def self.generate_uuid
    UUIDTools::UUID.timestamp_create.to_s
  end

  def self.translate_uuids_to_ids_in_params(params)
    params.transform_values! { |value| uuid?(value) ? find_id(value) : value }
  end

  def self.uuid?(value)
    value.is_a?(String) && value.match?(VALID_REGEXP)
  end

  def self.find_uuid_instance!(resource_type, resource_id)
    find_by!(resource_type:, resource_id:)
  end

  # Find the uuid corresponding id and system.
  # @param resource_type [String] the name of the external project
  # @param resource_id [String,  Integer ]
  # @return [String, nil] the uuid if found.

  def self.find_uuid(resource_type, resource_id)
    find_by(resource_type:, resource_id:).try(:external_id)
  end

  # Find an Uuid or create it if needed.
  # @param resource_type [String] the name of the external project
  # @param resource_id [String,  Integer ]
  # @return [String] the uuid .
  def self.find_uuid!(resource_type, resource_id)
    return unless resource_id # return nil for nil

    find_uuid(resource_type, resource_id) || create!(resource_type:, resource_id:).external_id
  end

  # Given a list of internal ids, create uuids in bulk
  # @param resource_type [String] the name of the external project
  # @param resource_ids [String,  Integer ]
  # @return [String] the uuid .
  def self.generate_uuids!(resource_type, resource_ids)
    return if resource_ids.empty?

    ids_missing_uuids = filter_uncreated_uuids(resource_type, resource_ids)
    uuids_to_create =
      ids_missing_uuids.map { |id| create!(resource_type: resource_type, resource_id: id, external_id: generate_uuid) }

    # Uuid.import uuids_to_create unless uuids_to_create.empty?

    nil
  end

  # ids is a string of internal_ids
  def self.filter_uncreated_uuids(resource_type, resource_ids)
    existing_uuids = where(resource_type: resource_type, resource_id: resource_ids)
    resource_ids - existing_uuids.pluck(:resource_id)
  end

  def self.generate_all_uuids_for_class(base_class_name)
    eval(base_class_name).find_in_batches(batch_size: 5000) do |group|
      generate_uuids!(base_class_name.to_s, group.map(&:id))
    end
  end

  # Find the id corresponding to the uuid. Check the resource and base_class names are as expected if they are given.
  # @param uuid [String]
  # @param resource_type [String] the name of the external project
  # @return [String, nil]
  # @raise Response::Exception if system doesn't macth.
  def self.find_id(uuid, resource_type = nil)
    with_external_id(uuid).limited_to_resource(resource_type).pick(:resource_id)
  end

  class << self
    def lookup_single_uuid(uuid)
      with_external_id(uuid).first or raise ActiveRecord::RecordNotFound, "Could not find UUID #{uuid.inspect}"
    end

    def lookup_many_uuids(uuids)
      with_external_id(uuids).all.tap do |found|
        missing = uuids - found.map(&:external_id)
        unless missing.empty?
          raise ActiveRecord::RecordNotFound, "Could not find UUIDs #{missing.map(&:inspect).join(',')}"
        end
      end
    end
  end
end
