# frozen_string_literal: true

require_relative 'client'
require_relative 'utils'

module EbiCheck
  class Process # rubocop:disable Metrics/ClassLength
    EGA = 'EGA'
    ENA = 'ENA'
    TEMP_STUDY_INFO = 'Study ID: %s, EBI Accession Number: %s'
    TEMP_SAMPLE_INFO = '  Sample ID: %s, EBI Accession Number: %s'
    TEMP_SC = 'SC:  %s=%s'
    TEMP_EBI = 'EBI: %s=%s'

    def studies_by_ids(study_ids)
      study_ids.each do |study_id|
        study = Study.find_by(id: study_id)
        print_study_info(study)

        xml = local_study_xml(study)
        local = extract_study_fields(xml)

        xml = remote_study_xml(study)
        remote = extract_study_fields(xml)

        print_differences(local, remote)
      end
    end

    def studies_by_accession_numbers(study_numbers)
      study_ids = Study::Metadata.where(study_ebi_accession_number: study_numbers).pluck(:study_id)
      studies_by_ids(study_ids)
    end

    def samples_by_study_ids(study_ids)
      study_ids.each do |study_id|
        study = Study.find_by(id: study_id)
        print_study_info(study)
        study.samples.each do |sample|
          check_sample(sample)
        end
      end
    end

    def samples_by_ids(sample_ids)
      samples = Sample.where(id: sample_ids)
      samples_by_study = samples.group_by { |sample| sample.studies.first }

      samples_by_study.each do |study, samples|
        print_study_info(study)
        samples.each do |sample|
          check_sample(sample)
        end
      end
    end

    def samples_by_accession_numbers(sample_numbers)
      sample_ids = Sample::Metadata.where(sample_ebi_accession_number: sample_numbers).pluck(:sample_id)
      samples_by_ids(sample_ids)
    end

    def samples_by_study_accession_numbers(study_numbers)
      study_ids = Study::Metadata.where(study_ebi_accession_number: study_numbers).pluck(:study_id)
      samples_by_study_ids(study_ids)
    end

    private

    delegate :extract_study_fields, to: EbiCheck::Utils
    delegate :extract_sample_fields, to: EbiCheck::Utils

    def check_sample(sample)
      print_sample_info(sample)

      xml = local_sample_xml(sample)
      local = extract_sample_fields(xml)

      xml = remote_sample_xml(sample)
      remote = extract_sample_fields(xml)

      print_differences(local, remote)
    end

    def local_study_xml(study)
      Accessionable::Study.new(study).xml
    end

    def remote_study_xml(study)
      client_for_study(study).get(study.ebi_accession_number).body.to_s
    end

    def local_sample_xml(sample)
      Accessionable::Sample.new(sample).xml
    end

    def remote_sample_xml(sample)
      client_for_sample(sample).get(sample.ebi_accession_number).body.to_s
    end

    # rubocop:disable Rails/Output
    def print_study_info(study)
      puts format(TEMP_STUDY_INFO, study.id, study.ebi_accession_number)
    end

    def print_sample_info(sample)
      puts format(TEMP_SAMPLE_INFO, sample.id, sample.ebi_accession_number)
    end

    def print_differences(local, remote)
      local.each do |key, value|
        remote_value = remote[key] || ''
        next unless value != remote_value

        next if (key == :'subject id') && (local[key] == remote[:title])

        puts format(TEMP_SC, key, value)
        puts format(TEMP_EBI, key, remote_value)
      end
    end
    # rubocop:enable Rails/Output

    def client_for_study(study)
      if study.ebi_accession_number.start_with?(EGA)
        client_for_ega_studies
      else
        client_for_ena_studies
      end
    end

    def client_for_sample(sample)
      if sample.ebi_accession_number.start_with?(EGA)
        client_for_ega_samples
      else
        client_for_ena_samples
      end
    end

    def client_for_ena_samples
      @client_for_ena_samples ||= EbiCheck::Client.for_ena_samples
    end

    def client_for_ega_samples
      @client_for_ega_samples ||= EbiCheck::Client.for_ega_samples
    end

    def client_for_ena_studies
      @client_for_ena_studies ||= EbiCheck::Client.for_ena_studies
    end

    def client_for_ega_studies
      @client_for_ega_studies ||= EbiCheck::Client.for_ega_studies
    end
  end
end
