# frozen_string_literal: true

class MoveConsentWithdrawnFromSamplesToSampleMetadata < ActiveRecord::Migration[5.2]
  def sample_id_and_consent_withdrawn
    Sample.select(:id, :migrated_consent_withdrawn_to_metadata)
  end

  def backup_file_path
    '/tmp/backup-samples-consent-2020021901.txt'
  end

  def is_boolean?(val)
    [true, false].include? val
  end

  def create_recovery_file!
    say "recovery file: #{backup_file_path}"
    backup_data = []
    sample_id_and_consent_withdrawn.each do |sample|
      tuple = [sample.id, sample.migrated_consent_withdrawn_to_metadata]
      raise 'Not an int' unless tuple[0].is_a?(Integer)
      raise 'Not a boolean value' unless is_boolean?(tuple[1])

      backup_data.push(tuple)
    end
    File.open(backup_file_path, 'w') { |file| file.write(backup_data.to_json) }
  end

  def get_recovery_data
    data_in_file = nil
    File.open(backup_file_path, 'r') { |file| data_in_file = JSON.parse(file.read) }
    data_in_file
  end

  def check_recovery_data!(data_in_file)
    raise 'Nothing read' if data_in_file.nil?
    raise 'Not a list' unless data_in_file.is_a?(Array)
    raise 'Empty list' if data_in_file.empty?
    raise 'Different set of samples than the one in database. Backup incorrect.' unless data_in_file.length == Sample.count

    data_in_file.each do |ident, value|
      raise "Value not an int #{ident}" unless ident.is_a?(Integer)
      raise "Value not a boolean #{ident}" unless is_boolean?(value)
    end
  end

  def up
    ActiveRecord::Base.transaction do
      Sample.reset_column_information
      Sample::Metadata.reset_column_information

      create_recovery_file!
      data_in_file = get_recovery_data
      check_recovery_data!(data_in_file)

      num_read = 0
      data_in_file.each do |ident, value|
        if value==true
          num_read = num_read + 1
          say "Moving to metadata consent withdrawn for sample #{ident} with value #{value}"
          sample = Sample.find_by!(id: ident)
          raise 'Not a sample' unless sample.is_a?(Sample)

          sample.sample_metadata.update!(consent_withdrawn: value)
          raise 'Data not updated' unless sample.sample_metadata.consent_withdrawn == value
        end
      end

      raise 'Inconsistent number of values ' unless Sample::Metadata.where(consent_withdrawn: true).count == num_read
      say 'Update complete!'
    end
  end

  def down
    ActiveRecord::Base.transaction do
      Sample.reset_column_information
      Sample::Metadata.reset_column_information

      data_in_file = get_recovery_data
      check_recovery_data!(data_in_file)


      # When rolling back we do one by one every sample
      data_in_file.each do |ident, value|
        say "Moving to sample consent withdrawn for sample #{ident} with value #{value}"
        sample = Sample.find_by!(id: ident)
        raise 'Not a sample' unless sample.is_a?(Sample)

        sample.update!(migrated_consent_withdrawn_to_metadata: value)
        raise 'Data not updated' unless sample.migrated_consent_withdrawn_to_metadata == value
      end
    end
  end
end
