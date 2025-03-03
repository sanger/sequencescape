# frozen_string_literal: true

# Descriptor fields is redundant now hashes are ordered. This migration
# updates historical data to ensure:
# - Hashes are sorted in the same order defined in order-fields
# - Any keys present in the array, but absent from the hash are recorded
# - Data missing a + in the hash key is repaired
class MigrateDescriptorFieldsIntoDescriptors < ActiveRecord::Migration[5.2]
  # The actual lab event has had the descriptor_fields serializer removed
  # so we need to add a version to us to use just for this migration
  class LabEvent < ApplicationRecord
    self.table_name = 'lab_events'
    serialize :descriptor_fields, type: Array
    serialize :descriptors

    def descriptor_hash
      read_attribute(:descriptors) || {}
    end
  end

  def up
    say 'Updating lab_events...'
    spinner = %w[🕛 🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚].cycle
    data =
      transaction do
        LabEvent.find_each.filter_map do |event|
          print "\r#{spinner.next} #{event.id}" # rubocop:disable Rails/Output
          simplify_event(event)
        end
      end
    backup_data(data)
  end

  def simplify_event(event)
    return nil if event.descriptor_fields == event.descriptor_hash.keys

    say ' - Repairing'

    backup = [event.id, event.descriptors_before_type_cast.dup, event.descriptor_fields_before_type_cast.dup]
    merged_descriptors = merge_descriptors(event.descriptor_fields, event.descriptor_hash)

    fix_keys!(merged_descriptors)

    event.write_attribute(:descriptors, merged_descriptors)
    event.save!
    backup
  end

  def merge_descriptors(fields, descriptors_hash)
    fields.select(&:present?).index_with { |_k| nil }.merge!(descriptors_hash)
  end

  def fix_keys!(merged_descriptors)
    # A historical bug resulted in the attributes beginning in a plus eg.
    # '+4 Temp. Sequencing Kit Lot #'
    # being incorrectly stores in the descriptors as ' 4 Temp. Sequencing Kit Lot #'
    # We'll fix that here to avoid duplicate field names
    # If both keys are present, we won't merge them
    good_keys = merged_descriptors.keys.select { |k| k.include?('+') }
    good_keys.each do |good_key|
      bad_key = good_key.tr('+', ' ')
      merged_descriptors[good_key] ||= merged_descriptors.delete(bad_key) if merged_descriptors[bad_key]
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'Cannot be rolled-back automatically. Check ~/MigrateDescriptorFieldsIntoDescriptors-*.csv'
  end

  def backup_data(data)
    timestamp = Time.zone.now.strftime('%Y%m%d%H%M%S')
    filename = Pathname(Dir.home).join("MigrateDescriptorFieldsIntoDescriptors-#{timestamp}.csv")

    CSV.open(filename, 'w') do |csv|
      csv << %w[event_id descriptors descriptor_fields]
      data.each { |row| csv << row }
    end

    say "Backed up to #{filename}", true
  end
end
