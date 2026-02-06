# frozen_string_literal: true
module Accession
  # Handles assigning of accessioning number to a Sequencescape sample.
  # Before accessioning:
  #  check configuration settings, in particular:
  #   configatron.proxy
  #   configatron.accession url, ega.user, ega.password, ena.user, ena.password
  #   configatron.accession_local_key (authorised user uuid)
  # check that Sequencescape sample sample_metadata meets accessioning requirements
  # feature flag y25_706_enable_accessioning should be set to true to automatically accession a sample after save
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

  require_relative '../app/helpers/accession_helper'

  String.include CoreExtensions::String

  # Generic high-level accessioning error
  # Usage: raise Accession::Error, "Accessioning failed: #{reason}"
  class Error < StandardError; end
  class ExternalValidationError < Error; end
  class InternalValidationError < Error; end

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

  # Returns a user-friendly error message based on the error type
  def self.user_error_message(error)
    case error
    when Accession::ExternalValidationError, Accession::InternalValidationError
      error.message
    when Faraday::Error
      'A network error occurred during accessioning and no response was received.'
    else
      'An internal error occurred during accessioning.'
    end
  end

  # --- Methods called by external controllers ---

  # Wrapper for sample accessioning with error handling and job management.
  # Allows accessioning to be triggered from anywhere in the application.
  # Encapsulates logic for validation, synchronous or asynchronous job execution,
  # and supports private helper methods for internal workflow.
  #
  # Note: does not include permission checks - these are Rails based and should be in the appropriate controller.
  #
  # @param sample [Sample] The sample to be accessioned.
  # @param event_user [User] The user triggering the accessioning event.
  # @param perform_now [Boolean] Whether to perform accessioning synchronously.
  # @return [void]
  # @raise [Accession::Error] for general accessioning errors.
  class SampleAccessioning
    include ::AccessionHelper

    def perform(sample, event_user, perform_now)
      return unless accessioning_enabled?
      return unless sample.should_be_accessioned?

      accessionable = build_accessionable(sample)
      job = SampleAccessioningJob.new(accessionable, event_user)

      if perform_now
        inline_accession_job!(job)
      else
        enqueue_accessioning_job!(job)
      end
    end

    def build_accessionable(sample)
      Accession::Sample.new(Accession.configuration.tags, sample)
    end

    private

    # Perform accessioning job synchronously
    def inline_accession_job!(job)
      job.enqueue(nil) # create status
      job.before(nil) # set status to processing
      begin
        job.perform # this runs the job immediately
        job.success(nil) # remove statuses
      rescue StandardError
        job.failure(nil) # set last status to aborted
        raise
      end
    end

    def enqueue_accessioning_job!(sample_accessioning_job)
      # Accessioning jobs are lower priority (higher number) than submissions and reports
      job = Delayed::Job.enqueue(sample_accessioning_job, priority: 200)
      log_job_status(job)
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
