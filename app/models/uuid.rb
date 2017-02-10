# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class Uuid < ActiveRecord::Base
  # Allows tests to dictate the next UUID generted for a given class
  class_attribute :store_for_tests

  module Uuidable
    def self.included(base)
      base.class_eval do
        # We need to add some class level changes to this model because the ar-extensions gem might be
        # used.
        # extend ArExtensionsFix

        # Ensure that the resource has a UUID and that it's always created when the instance is created.
        # It seems better not to do this but the performance of the API is directly affected by having to
        # create these instances when they do not exist.
        has_one :uuid_object, class_name: 'Uuid', as: :resource, dependent: :destroy, inverse_of: :resource
        after_create :ensure_uuid_created

        # Some named scopes ...
        scope :include_uuid, -> { includes(:uuid_object) }
      end
    end

    # In the test environment we need to have a slightly different behaviour, as we can predefine
    # the UUID for a record to make things predictable.  In production new records always have new
    # UUIDs.
    if ['test', 'cucumber'].include?(Rails.env)
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

    # The behaviour of the ar-extensions gem means that the after_create callbacks aren't being executed
    # for any of the rows we create on import.  What we need to do is ensure that any rows in the table
    # that do not have UUIDs have their UUIDs created, but we also need to do this unobtrusively.
    module ArExtensionsFix
      def self.extended(base)
        base.singleton_class.alias_method_chain(:import, :uuid_creation)
      end

      def import_with_uuid_creation(*args, &block)
        import_without_uuid_creation(*args, &block).tap do |results|
          generate_missing_uuids unless results.num_inserts.zero?
        end
      end

      def generate_missing_uuids
        records_for_missing_uuids { |id| Uuid.create!(resouce_type: name, resource_id: id, external_id: Uuid.generate_uuid) }
      end
      private :generate_missing_uuids

      def records_for_missing_uuids
        connection.select_all(%Q{
          SELECT r.id AS id
          FROM #{quoted_table_name} r
          LEFT OUTER JOIN #{Uuid.quoted_table_name} u
          ON r.id=u.resource_id AND u.resource_type="#{self}"
          WHERE u.id IS NULL
        }).map { |r| yield(r['id']) }
      end
      private :records_for_missing_uuids
    end
  end

  ValidRegexp = /\A[\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12}\z/
  validates_format_of :external_id, with: ValidRegexp

  # It is more efficient to check the individual parts of the resource association than it is to check the
  # association itself as the latter causes the record to be reloaded
  belongs_to :resource, polymorphic: true, inverse_of: :uuid_object

  # TODO[xxx]: remove this and use resource everywhere!
  def object
    resource
  end

  scope :with_resource_type, ->(type) { where(resource_type: type.to_s) }

  scope :include_resource, -> { includes(:resource) }
  scope :with_external_id, ->(external_id) { where(external_id: external_id) }
  scope :with_resource_by_type_and_id, ->(t, id) { where(resource_type: t, resource_id: id) }

  before_validation do |record|
    record.external_id = Uuid.generate_uuid if record.new_record? and record.external_id.blank?
  end

  def uuid
    external_id
  end

  def self.generate_uuid
    UUIDTools::UUID.timestamp_create.to_s
  end

  def self.translate_uuids_to_ids_in_params(params)
    params.keys.each do |key|
      next unless params[key] =~ ValidRegexp
      params[key] = find_id(params[key])
    end
  end

  def self.find_uuid_instance!(resource_type, resource_id)
    with_resource_by_type_and_id(resource_type, resource_id).first or
      raise ActiveRecord::RecordNotFound, 'Unable to find UUID'
  end

  # Find the uuid corresponding id and system.
  # @param resource_name [String] the name of the external project
  # @param id [String,  Integer ]
  # @return [String, nil] the uuid if found.

  def self.find_uuid(resource_type, resource_id)
    begin
      find_uuid_instance!(resource_type, resource_id).external_id
    rescue ActiveRecord::RecordNotFound => exception
      return nil
    end
  end

  # Find an Uuid or create it if needed.
  # @param resource_name [String] the name of the external project
  # @param id [String,  Integer ]
  # @return [String] the uuid .
  def self.find_uuid!(resource_type, resource_id)
    return unless id # return nil for nil
    find_uuid(resource_type, resource_id) ||
      create!(resource_type: resource_type, resource_id: resource_id).external_id
  end

  # Given a list of internal ids, create uuids in bulk
  # @param resource_name [String] the name of the external project
  # @param base_class_name [String] the basic type in the external project.
  # @param id [String,  Integer ]
  # @return [String] the uuid .
  def self.generate_uuids!(resource_type, resource_ids)
    return if resource_ids.empty?
    ids_missing_uuids = filter_uncreated_uuids(resource_type, resource_ids)
    uuids_to_create = ids_missing_uuids.map { |id| create!(resource_type: resource_type, resource_id: id, external_id: generate_uuid) }
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
  # @param resource_name [String] the name of the external project
  # @return [String, nil]
  # @raise Response::Exception if system doesn't macth.
  def self.find_id(uuid, resource_type = nil)
    begin
      uuid_object = with_external_id(uuid).first or raise ActiveRecord::RecordNotFound, "Could not find UUID #{uuid.inspect}"

      Response::InvalidUuid.throw_new(uuid) if resource_type && resource_type != uuid_object.resource_type

      uuid_object.resource_id
    rescue
      return nil
    end
  end

  class << self
    def lookup_single_uuid(uuid)
      with_external_id(uuid).first or
        raise ActiveRecord::RecordNotFound, "Could not find UUID #{uuid.inspect}"
    end

    def lookup_many_uuids(uuids)
      with_external_id(uuids).all.tap do |found|
        missing = uuids - found.map(&:external_id)
        raise ActiveRecord::RecordNotFound, "Could not find UUIDs #{missing.map(&:inspect).join(',')}" unless missing.empty?
      end
    end
  end
end
