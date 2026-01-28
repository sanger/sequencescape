# frozen_string_literal: true
module Accession
  # Made up of a sample, user and service
  # Used by Request to extract relevant information to send to appropriate accessioning service
  class Submission
    include ActiveModel::Model
    include Accession::Accessionable

    attr_reader :sample, :service

    delegate :accessioned?, :ebi_alias, :ebi_alias_datestamped, to: :sample

    validates_presence_of :sample
    validate :check_sample, if: proc { |s| s.sample.present? }

    def initialize(sample)
      @sample = sample
      @service = sample&.service
    end

    # Define the client as a class method for easy test mocking
    def self.client
      HTTPClients::AccessioningV1Client.new
    end

    def build_xml(xml)
      xml.SUBMISSION(
        XML_NAMESPACE,
        center_name: CENTER_NAME,
        broker_name: service.broker,
        alias: sample.ebi_alias_datestamped,
        submission_date: date
      ) do
        actions(xml)
      end
    end

    def submit_accession(event_user) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      # Rubocop metrics disabled as refactoring this method would reduce clarity
      unless valid?
        raise Accession::InternalValidationError,
              "Accessionable submission is invalid: #{errors.full_messages.join(', ')}"
      end

      client = self.class.client
      login = service.login
      files = compile_files

      if accessioned?
        client.submit_and_fetch_accession_number(login, files)
        sample.sample.events.updated_accessioned_metadata!('sample', event_user)
        Rails.logger.info("Sample '#{sample.sample.name}' " \
                          "with alias '#{sample.ebi_alias}' " \
                          "and accession number '#{sample.ebi_accession_number}' " \
                          "has had it's accession metadata successfully updated.")
      else
        accession_number = client.submit_and_fetch_accession_number(login, files)
        sample.update_accession_number(accession_number, event_user)
      end
    ensure
      # Ensure all opened files are closed
      files&.each_value(&:close!)
    end

    # Returns a hash mapping file type names to File objects.
    # Files should be closed or unlinked after use.
    # {
    #   'SUBMISSION' => open_temp_submission_file,
    #   'SAMPLE' => open_temp_sample_file
    # }
    def compile_files
      {}.tap do |f|
        [self, sample].each do |accessionable|
          f[accessionable.schema_type.upcase] = accessionable.to_file
        end
      end
    end

    private

    # Validates the associated sample object.
    # If the sample is invalid, adds each of its validation errors to the Submission's errors.
    #
    # This ensures that any validation errors on the sample are also reported on the Submission,
    # making them visible when validating a Submission instance.
    def check_sample
      service_provider = sample.service.provider.to_sym
      unless sample.valid?([:accession, service_provider]) # Check against accessioning contexts
        sample.errors.each { |error| errors.add error.attribute, error.message }
      end
    end

    # Returns true if the provided sample has an accession number, false otherwise.
    def accession_number?
      # The first sample is an Accession::Sample, the second is the standard model Sample.
      sample.sample.accession_number?
    end

    def actions(xml)
      xml.ACTIONS do
        xml.ACTION do
          if accession_number?
            xml.MODIFY(source: sample.filename)
          else
            xml.ADD(source: sample.filename, schema: sample.schema_type)
          end
        end
        xml.ACTION { xml.tag!(service.visibility) }
      end
    end
  end
end
