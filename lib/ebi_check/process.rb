# frozen_string_literal: true

require 'hashdiff'

require_relative 'client'
require_relative 'utils'

# This module provides functionality to process and compare the Sequencescape
# generated local XML for studies and samples against the remote XML data
# retrieved from the EBI EGA and ENA services.
#
# It includes methods to check studies and samples by their IDs or accession
# numbers, retrieve the corresponding XML data, extract relevant fields, and
# print any differences found between the local and remote data.
#
# Example usage:
#
#   process = EBICheck::Process.new
#
#   process.studies_by_ids([123, 456])
#   process.studies_by_accession_numbers(['ERP123456', 'EGAS12345678901'])
#
#   process.samples_by_study_ids([123, 456])
#   process.samples_by_study_accession_numbers(['ERP123456', 'EGAS12345678901'])
#
#   process.samples_by_ids([789, 1011])
#   process.samples_by_accession_numbers(['ERS12345678', 'EGAN12345678901'])
#
module EBICheck
  class Process # rubocop:disable Metrics/ClassLength
    # Service names to identify EGA and ENA accessions
    EGA = 'EGA'
    ENA = 'ENA'
    # Templates for printing information
    TEMPLATE_STUDY_INFO = 'Study ID: %s, EBI Accession Number: %s'
    TEMPLATE_STUDY_ERROR = ' Error retrieving study XML - %s'
    TEMPLATE_SAMPLE_INFO = ' Sample ID: %s, EBI Accession Number: %s'
    TEMPLATE_SAMPLE_ERROR = '  Error retrieving sample XML - %s'
    TEMPLATE_SC = '  SC:  %s=%s'  # SC = Sequencescape side
    TEMPLATE_EBI = '  EBI: %s=%s' # EBI = EBI EGA / ENA side

    # Initializes a new EBICheck::Process instance.
    # @param out [IO] The output stream for printing results (default: $stdout).
    def initialize(out = $stdout)
      @out = out
    end

    # Compares local and remote study XML data for the given study IDs.
    # @param study_ids [Array<Integer>] The IDs of the studies to check.
    # @return [void]
    def studies_by_ids(study_ids) # rubocop:disable Metrics/MethodLength
      study_ids.each do |study_id|
        study = Study.find_by(id: study_id)
        print_study_info(study)

        xml = local_study_xml(study)
        local = extract_study_fields(xml)

        xml = remote_study_xml(study)
        remote = extract_study_fields(xml)

        print_differences(local, remote)
      rescue Faraday::Error => e
        out.puts format(TEMPLATE_STUDY_ERROR, e.message)
      end
    end

    # Compares local and remote study XML data for the given study accession numbers.
    # @param study_numbers [Array<String>] The accession numbers of the studies to check.
    # @return [void]
    def studies_by_accession_numbers(study_numbers)
      study_ids = Study::Metadata.where(study_ebi_accession_number: study_numbers).pluck(:study_id)
      studies_by_ids(study_ids)
    end

    # Compares local and remote sample XML data for the given study IDs.
    # @param study_ids [Array<Integer>] The IDs of the studies whose samples to check.
    # @return [void]
    def samples_by_study_ids(study_ids) # rubocop:disable Metrics/MethodLength
      study_ids.each do |study_id|
        study = Study.find_by(id: study_id)
        print_study_info(study)
        study.samples.each do |sample|
          check_sample(sample)
        rescue StandardError, Faraday::Error => e
          out.puts format(TEMPLATE_SAMPLE_ERROR, e.message)
        end
      rescue Faraday::Error => e
        out.puts format(TEMPLATE_STUDY_ERROR, e.message)
      end
    end

    # Compares local and remote sample XML data for the given sample IDs.
    # @param sample_ids [Array<Integer>] The IDs of the samples to check.
    # @return [void]
    def samples_by_ids(sample_ids) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      samples = Sample.where(id: sample_ids)
      samples_by_study = samples.group_by { |sample| sample.studies.first }

      samples_by_study.each do |study, samples|
        print_study_info(study)
        samples.each do |sample|
          check_sample(sample)
        rescue StandardError, Faraday::Error => e
          out.puts format(TEMPLATE_SAMPLE_ERROR, e.message)
        end
      rescue Faraday::Error => e
        out.puts format(TEMPLATE_STUDY_ERROR, e.message)
      end
    end

    # Compares local and remote sample XML data for the given sample accession numbers.
    # @param sample_numbers [Array<String>] The accession numbers of the samples to check.
    # @return [void]
    def samples_by_accession_numbers(sample_numbers)
      sample_ids = Sample::Metadata.where(sample_ebi_accession_number: sample_numbers).pluck(:sample_id)
      samples_by_ids(sample_ids)
    end

    # Compares local and remote sample XML data for the given study accession numbers.
    # @param study_numbers [Array<String>] The accession numbers of the studies whose samples to check.
    # @return [void]
    def samples_by_study_accession_numbers(study_numbers)
      study_ids = Study::Metadata.where(study_ebi_accession_number: study_numbers).pluck(:study_id)
      samples_by_study_ids(study_ids)
    end

    private

    delegate :extract_study_fields, to: EBICheck::Utils
    delegate :extract_sample_fields, to: EBICheck::Utils

    attr_reader :out # The output stream for printing results.

    # Compares local and remote XML data for a given sample.
    # @param sample [Sample] The sample to check.
    # @return [void]
    def check_sample(sample)
      raise StandardError, "Sample '#{sample.name}' does not have an accession number" unless sample.accession_number?

      print_sample_info(sample)

      xml = local_sample_xml(sample)
      local = extract_sample_fields(xml)

      xml = remote_sample_xml(sample)
      remote = extract_sample_fields(xml)

      print_differences(local, remote)
    end

    # Generates the local study XML for the given study.
    # @param study [Study] The study to generate XML for.
    # @return [String] The local study XML.
    def local_study_xml(study)
      Accessionable::Study.new(study).xml
    end

    # Retrieves the remote study XML for the given study from EBI.
    # @param study [Study] The study to retrieve XML for.
    # @return [String] The remote study XML.
    def remote_study_xml(study)
      client_for_study(study).get(study.ebi_accession_number).body.to_s
    end

    # Generates the local sample XML for the given sample.
    # @param sample [Sample] The sample to generate XML for.
    # @return [String] The local sample XML.
    def local_sample_xml(sample)
      tags = Accession.configuration.tags
      Accession::Sample.new(tags, sample).to_xml
    end

    # Retrieves the remote sample XML for the given sample from EBI.
    # @param sample [Sample] The sample to retrieve XML for.
    # @return [String] The remote sample XML.
    def remote_sample_xml(sample)
      client_for_sample(sample).get(sample.ebi_accession_number).body.to_s
    end

    # Prints information about a study, including its ID and EBI accession number.
    # @param study [Study] The study to print information for.
    # @return [void]
    def print_study_info(study)
      out.puts format(TEMPLATE_STUDY_INFO, study.id, study.ebi_accession_number)
    end

    # Prints information about a sample, including its ID and EBI accession number.
    # @param sample [Sample] The sample to print information for.
    # @return [void]
    def print_sample_info(sample)
      out.puts format(TEMPLATE_SAMPLE_INFO, sample.id, sample.ebi_accession_number)
    end

    # Prints the differences between local and remote data.
    # @param local [Hash] The local data.
    # @param remote [Hash] The remote data.
    # @return [void]
    def print_differences(local, remote) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      diffs = Hashdiff.diff(local, remote, indifferent: true, ignore_keys: [:'subject id', :title])
      return if diffs.empty?

      diffs = diffs.sort_by { |_diff_type, key, *_values| key } # Sort by key name for consistent output

      diffs.each do |diff_type, key, value, remote_value|
        case diff_type
        when '~' # Changed value - ['~', key, local_value, remote_value]
          out.puts format(TEMPLATE_SC, key, value) # Local value
          out.puts format(TEMPLATE_EBI, key, remote_value)
        when '-' # Key missing in remote - ['-', key, value]
          out.puts format(TEMPLATE_SC, key, value)
          out.puts format(TEMPLATE_EBI, key, '<missing>')
        when '+' # Key missing in local - ['+', key, value]
          out.puts format(TEMPLATE_SC, key, '<missing>')
          out.puts format(TEMPLATE_EBI, key, value)
        end
      end
    end

    # Returns the appropriate client for accessing study data based on the
    # study's EBI accession number, i.e. EGA or ENA.
    # @param study [Study] The study to get the client for.
    # @return [EBICheck::Client] The client for accessing the study data.
    def client_for_study(study)
      if study.ebi_accession_number.start_with?(EGA)
        client_for_ega_studies
      else
        client_for_ena_studies
      end
    end

    # Returns the appropriate client for accessing sample data based on the
    # sample's EBI accession number, i.e. EGA or ENA.
    # @param sample [Sample] The sample to get the client for.
    # @return [EBICheck::Client] The client for accessing the sample data.
    def client_for_sample(sample)
      if sample.ebi_accession_number.start_with?(EGA)
        client_for_ega_samples
      else
        client_for_ena_samples
      end
    end

    # Memoized client for ENA samples for reuse.
    # @return [EBICheck::Client] The ENA samples client.
    def client_for_ena_samples
      @client_for_ena_samples ||= EBICheck::Client.for_ena_samples
    end

    # Memoized client for EGA samples for reuse.
    # @return [EBICheck::Client] The EGA samples client.
    def client_for_ega_samples
      @client_for_ega_samples ||= EBICheck::Client.for_ega_samples
    end

    # Memoized client for ENA studies for reuse.
    # @return [EBICheck::Client] The ENA studies client.
    def client_for_ena_studies
      @client_for_ena_studies ||= EBICheck::Client.for_ena_studies
    end

    # Memoized client for EGA studies for reuse.
    # @return [EBICheck::Client] The EGA studies client.
    def client_for_ega_studies
      @client_for_ega_studies ||= EBICheck::Client.for_ega_studies
    end
  end
end
