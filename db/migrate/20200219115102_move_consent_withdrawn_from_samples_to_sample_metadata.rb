# frozen_string_literal: true

# NB: 2020-Feb-21 The column consent_withdrawn was recovered in the Samples table. The procedure
# has been reviewed to perform the update.
# This migration creates a backup file with the contents that are going to be migrated. Then it
# validates and copies the data from the backup into the new column in SampleMetadata. If it
# finds any error during validation or copying it rollsback all the migration.
# Also provides a procedure to rollback changes.
class MoveConsentWithdrawnFromSamplesToSampleMetadata < ActiveRecord::Migration[5.2]
  def sample_id_and_consent_withdrawn
    Sample.select(:id, :migrated_consent_withdrawn_to_metadata)
  end

  def backup_file_path
    '/var/tmp/backup-samples-consent-2020021901.txt'
  end

  def boolean?(val)
    [true, false].include? val
  end

  def create_recovery_file!
    say "recovery file: #{backup_file_path}"
    backup_data = []
    sample_id_and_consent_withdrawn.each do |sample|
      tuple = [sample.id, sample.migrated_consent_withdrawn_to_metadata]
      raise 'Not an int' unless tuple[0].is_a?(Integer)
      raise 'Not a boolean value' unless boolean?(tuple[1])

      backup_data.push(tuple)
    end
    File.write(backup_file_path, backup_data.to_json)
  end

  def recovery_data
    data_in_file = nil
    File.open(backup_file_path, 'r') { |file| data_in_file = JSON.parse(file.read) }
    data_in_file
  end

  def check_recovery_data!(data_in_file) # rubocop:disable Metrics/CyclomaticComplexity
    raise 'Nothing read' if data_in_file.nil?
    raise 'Not a list' unless data_in_file.is_a?(Array)
    raise 'Empty list' if data_in_file.empty?
    unless data_in_file.length == Sample.count
      raise 'Different set of samples than the one in database. Backup incorrect.'
    end

    data_in_file.each do |ident, value|
      raise "Value not an int #{ident}" unless ident.is_a?(Integer)
      raise "Value not a boolean #{ident}" unless boolean?(value)
    end
  end

  def up # rubocop:disable Metrics/AbcSize
    ActiveRecord::Base.transaction do
      Sample.reset_column_information
      Sample::Metadata.reset_column_information

      create_recovery_file!
      data_in_file = recovery_data
      check_recovery_data!(data_in_file)

      # Consent withdrawn in sample metadata should not be in use at now but if it had any values all of them are reset
      # to false
      # The right value for consent withdrawn before this migration is in samples, so the next steps will copy that
      # value
      Sample::Metadata.where(consent_withdrawn: true).update_all(consent_withdrawn: false)

      num_read = 0
      data_in_file.each do |ident, value|
        next unless value == true

        num_read += 1
        say "Moving to metadata consent withdrawn for sample #{ident} with value #{value}"
        sample = Sample.find(ident)
        raise 'Not a sample' unless sample.is_a?(Sample)

        sample.sample_metadata.update!(consent_withdrawn: value)
        raise 'Data not updated' unless sample.sample_metadata.consent_withdrawn == value
      end

      raise 'Inconsistent number of values ' unless Sample::Metadata.where(consent_withdrawn: true).count == num_read

      say 'Update complete!'
    end
  end
end
