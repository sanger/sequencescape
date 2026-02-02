# frozen_string_literal: true

# Rake tasks for checking study and sample data uploaded to the EBI EGA & ENA databases.
#
# Tasks:
# - ebi:check_studies: Checks studies by Sequencescape study IDs or EBI accession numbers.
#   Usage:
#     bundle exec rake ebi:check_studies study_ids=123,456
#     bundle exec rake ebi:check_studies study_numbers=ERP123456,EGAS12345678901
#
# - ebi:check_samples: Checks samples by study/sample IDs or accession numbers.
#   Usage:
#     bundle exec rake ebi:check_samples study_ids=123,456
#     bundle exec rake ebi:check_samples sample_ids=789,1011
#     bundle exec rake ebi:check_samples study_numbers=ERP123456,EGAS12345678901
#     bundle exec rake ebi:check_samples sample_numbers=ERS12345678,EGAN12345678901
#
# These tasks compare local Sequencescape XML with remote EBI/ENA/EGA XML,
# extract relevant fields, and print any differences found.
#
# rubocop:disable Rails/Output
namespace :ebi do
  desc 'Check study data uploaded to the EBI EGA & ENA databases'
  task :check_studies, [:study_ids] => :environment do
    study_ids = (ENV['study_ids'] || '').split(',').reject(&:empty?)
    study_numbers = (ENV['study_numbers'] || '').split(',').reject(&:empty?)
    if study_ids.empty? && study_numbers.empty?
      puts <<~USAGE
        Usage: bundle exec rake ebi:check_studies study_ids=<study_id>,... \
          study_numbers=<study_number>,...
        Example: bundle exec rake ebi:check_studies study_ids=123,456
        Example: bundle exec rake ebi:check_studies study_numbers=ERP123456,EGAS12345678901
      USAGE
      exit 1
    end

    process = EbiCheck::Process.new

    if study_ids.any?
      puts 'Processing Study IDs'
      process.studies_by_ids(study_ids)
    end

    if study_numbers.any?
      puts 'Processing Study Accession Numbers'
      process.studies_by_accession_numbers(study_numbers)
    end
  end

  desc 'Check sample data uploaded to the EBI EGA & ENA databases'
  task :check_samples, %i[study_ids sample_ids study_numbers sample_numbers] => :environment do
    study_ids = (ENV['study_ids'] || '').split(',').reject(&:empty?)
    sample_ids = (ENV['sample_ids'] || '').split(',').reject(&:empty?)
    study_numbers = (ENV['study_numbers'] || '').split(',').reject(&:empty?)
    sample_numbers = (ENV['sample_numbers'] || '').split(',').reject(&:empty?)

    if study_ids.empty? && sample_ids.empty? && study_numbers.empty? && sample_numbers.empty?

      puts <<~USAGE
        Usage: bundle exec rake ebi:check_samples \
          study_ids=<study_id>,... \
          sample_ids=<sample_id>,... \
          study_numbers=<study_number>,... \
          sample_numbers=<sample_number>,...
        Example: bundle exec rake ebi:check_samples study_ids=123,456
        Example: bundle exec rake ebi:check_samples sample_ids=789,1011
        Example: bundle exec rake ebi:check_samples study_numbers=ERP123456,EGAS12345678901
        Example: bundle exec rake ebi:check_samples sample_numbers=ERS12345678,EGAN12345678901
      USAGE
      exit 1
    end

    process = EbiCheck::Process.new

    if study_ids.any?
      puts 'Processing Study IDs'
      process.samples_by_study_ids(study_ids)
    end

    if sample_ids.any?
      puts 'Processing Sample IDs'
      process.samples_by_ids(sample_ids)
    end

    if study_numbers.any?
      puts 'Processing Study Accession Numbers'
      process.samples_by_study_accession_numbers(study_numbers)
    end

    if sample_numbers.any?
      puts 'Processing Sample Accession Numbers'
      process.samples_by_accession_numbers(sample_numbers)
    end
  end
end
# rubocop:enable Rails/Output
