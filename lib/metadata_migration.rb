# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012 Genome Research Ltd.
class MetadataMigration < ActiveRecord::Migration
  class Property < ActiveRecord::Base
    class Definition < ActiveRecord::Base
      self.table_name = ('property_definitions')
      has_many :properties, class_name: 'MetadataMigration::Property', foreign_key: :property_definition_id, dependent: :destroy

     scope :for_class, ->(c) { where(relates_to: c) }
     scope :for_keys, ->(keys) { where(key: keys) }

      # It's more efficient to delete all of the properties and then delete the definition.
      def self.delete_for(relates_to, keys)
        definition_ids = for_class(relates_to).for_keys(keys).all.map(&:id)
        Property.delete_all(['property_definition_id IN (?)', definition_ids])
        delete_all(['id IN (?)', definition_ids])
      end
    end

    self.table_name = ('properties')
    belongs_to :definition, class_name: 'MetadataMigration::Property::Definition', foreign_key: :property_definition_id
  end

  def self.reference_class_name
    reference_class.name.sub(/^[^:]+::/, '')
  end

  def self.properties_from_metadata
    metadata_class.column_names.reject do |name|
      [:id, reference_id].include?(name.to_sym)
    end.inject({}) do |hash, p|
      returning(hash) do
        hash[p] = Property::Definition.find_by(relates_to: reference_class_name, key: p.to_s) or raise StandardError, "Cannot find property definition for '#{p}'"
      end
    end
  end

  # Migrates all of the property instances to their related metadata instances
  def self.migrate_properties
    properties = properties_from_metadata

    say("There are #{reference_class.count} records to process")

    start = 0
    reference_class.find_in_batches(batch_size: 1500, include: :properties) do |records|
      say_with_time("Processing #{start}-#{start + records.length}") do
        # Create new objects that can be validated.
        objects = records.map do |record|
          metadata_class.new(
            properties.inject(reference_id.to_s => record.id) do |attributes, (property, definition)|
              returning(attributes) do
                attributes[property.to_s] = record.properties.detect { |p|
                  p.property_definition_id == definition.id
                }.try(:value)
              end
            end
          )
        end

        # If there is a single record that fails validation try saving each one.  That way the InvalidRecord error
        # will be raised and we'll know which one failed!  Otherwise we can bulk save these.
        objects.map(&:save!) unless objects.all?(&:valid?)
        metadata_class.import(objects)
      end

      start += records.length
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      create_metadata_table
      begin
        say('Migrating all of the properties (this might take a very long time!)')
        metadata_class.reset_column_information
        migrate_properties

        # Delete all of the properties that we have migrated, leaving any that may exist outside that.
        say('Destroying all of the migrated property definitions')
        Property::Definition.delete_for(reference_class_name, metadata_class.column_names.reject do |name|
          [:id, reference_id].include?(name.to_sym)
        end)
      rescue
        drop_table(metadata_class.table_name)
        raise
      end
    end
  rescue ActiveRecord::RecordInvalid => exception
    $stderr.puts "Invalid record: #{exception.record.inspect}"
    raise
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Cannot reverse property to metadata migration'
  end
end
