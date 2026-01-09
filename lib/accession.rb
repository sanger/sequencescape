# frozen_string_literal: true
module Accession
  # Handles assigning of accessioning number to a Sequencescape sample.
  # Before accessioning:
  #  check configuration settings, in particular:
  #   configatron.proxy
  #   configatron.accession url, ega.user, ega.password, ena.user, ena.password
  #   configatron.accession_local_key (authorised user uuid)
  # check that Sequencescape sample sample_metadata meets accessioning requirements
  # configatron.accession_samples flag should be set to true to automatically accession a sample after save
  # (app/models/sample.rb)
  #
  # Accessioning steps:
  #  1. Create new Accession::Sample, with tags hash (Accession.configuration.tags) and a Sequencescape sample as
  #     arguments.
  #  2. Checks if a new accession sample is valid (it will check if Sequencescape sample can be accessioned).
  #  3. Create new Accession::Submission, with authorised user and a valid accession sample as arguments.
  #  4. If the submission is valid, submit it using AccessioningV1Client.submit_and_fetch_accession_number.
  #  5. The client will submit the submission to the external accessioning service API and return an accession number.
  #  6. The submission will update the Sequencescape sample with the new accession number.
  #  7. If any step fails, an Accession::Error, Faraday::Error or StandardError will be raised and needs to be handled.
  #
  # An example of usage is provided in Sequencescape app/jobs/sample_accessioning_job.rb
  #
  # @see ftp://ftp.sra.ebi.ac.uk/meta/xsd/ Schema definitions
  module Helpers
    def load_file(folder, filename)
      YAML.load_file(Rails.root.join(folder, "#{filename}.yml")).with_indifferent_access
    end
  end

  module Equality
    include Comparable

    def to_a
      attributes.filter_map { |v| instance_variable_get("@#{v}") }
    end

    ##
    # Two objects are comparable if all of their instance variables that are present
    # are comparable.
    def <=>(other)
      return unless other.is_a?(self.class)

      to_a <=> other.to_a
    end
  end

  require_relative 'accession/core_extensions'
  require_relative 'accession/accessionable'
  require_relative 'accession/contact'
  require_relative 'accession/service'
  require_relative 'accession/sample'
  require_relative 'accession/tag'
  require_relative 'accession/tag_list'
  require_relative 'accession/submission'
  require_relative 'accession/configuration'

  String.include CoreExtensions::String

  # Generic high-level accessioning error
  # Usage: raise Accession::Error, "Accessioning failed: #{reason}"
  class Error < StandardError; end
  class ExternalValidationError < Error; end

  CENTER_NAME = 'SC'
  XML_NAMESPACE = { 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance' }.freeze

  # See app/models/accession.rb
  def self.table_name_prefix
    'accession_'
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset!
    @configuration = Configuration.new
  end

  # --- Methods called by external controllers ---

  # Wrapper for sample accessioning with error handling and job management.
  # Allows accessioning to be triggered from anywhere in the application.
  # Encapsulates logic for validation, synchronous or asynchronous job execution,
  # and supports private helper methods for internal workflow.
  class SampleAccessioning
    def perform(sample, event_user, perform_now)
      # Flag set in the deployment project to allow per-environment enabling of accessioning
      unless configatron.accession_samples
        raise AccessionService::AccessioningDisabledError, 'Accessioning is not enabled in this environment.'
      end

      accessionable = build_accessionable(sample)
      validate_accessionable!(accessionable)

      if perform_now
        # Perform accessioning job synchronously
        SampleAccessioningJob.new(accessionable, event_user).perform
      else
        enqueue_accessioning_job!(accessionable, event_user)
      end
    end

    private

    def build_accessionable(sample)
      Accession::Sample.new(Accession.configuration.tags, sample)
    end

    def validate_accessionable!(accessionable)
      return if accessionable.valid?

      error_message = "Sample '#{accessionable.sample.name}' cannot be accessioned: " \
                      "#{accessionable.errors.full_messages.join(', ')}"
      Rails.logger.error(error_message)
      raise AccessionService::AccessionValidationFailed, error_message
    end

    def enqueue_accessioning_job!(accessionable, event_user)
      job = Delayed::Job.enqueue(SampleAccessioningJob.new(accessionable, event_user), priority: 200)
      log_job_status(job)
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: 'Failed to enqueue accessioning job' })
      Rails.logger.error("Failed to enqueue accessioning job: #{e.message}")
      raise
    end

    def log_job_status(job)
      if job
        Rails.logger.info("Accessioning job enqueued successfully: #{job.inspect}")
      else
        Rails.logger.warn('Accessioning job enqueue returned nil.')
      end
    end
  end

  def self.accession_sample(sample, event_user, perform_now: false)
    SampleAccessioning.new.perform(sample, event_user, perform_now)
  end
end
