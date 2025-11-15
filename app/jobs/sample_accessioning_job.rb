# frozen_string_literal: true

require 'exception_notification'

# Sends sample data to the ENA or EGA in order to generate an accession number
# Records the generated accession number on the sample
# @see Accession::Submission
SampleAccessioningJob =
  Struct.new(:accessionable) do
    # Retrieve the contact user for accessioning submissions
    def self.contact_user
      User.find_by(api_key: configatron.accession_local_key)
    end

    def perform
      contact_user = self.class.contact_user
      submission = Accession::Submission.new(contact_user, accessionable)
      submission.submit_and_update_accession_number
    rescue StandardError => e
      handle_accession_error(e, submission)
    end

    def reschedule_at(current_time, _attempts)
      current_time + 1.day
    end

    def max_attempts
      3
    end

    def queue_name
      'sample_accessioning'
    end

    private

    def handle_accession_error(error, submission)
      sample_name = submission.sample.sample.name
      service = submission.service
      message = "SampleAccessioningJob failed for sample '#{sample_name}': #{error.message}"

      Rails.logger.error(message)
      ExceptionNotifier.notify_exception(error, data: {
                                           message: message,
                                           sample_name: sample_name,
                                           service_provider: service&.provider.to_s
                                         })
    end
  end
