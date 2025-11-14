# frozen_string_literal: true

require 'exception_notification'

# Sends sample data to the ENA or EGA in order to generate an accession number
# Records the generated accession number on the sample
# @see Accession::Submission
SampleAccessioningJob =
  Struct.new(:accessionable) do
    def perform
      submission = Accession::Submission.new(User.find_by(api_key: configatron.accession_local_key), accessionable)
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

    def handle_accession_error(error, submission, cause)
      sample_name = submission.sample.sample.name
      service = submission.service
      message = "SampleAccessioningJob failed for sample '#{sample_name}': #{cause}"

      Rails.logger.error(error.message)
      ExceptionNotifier.notify_exception(error, data: {
                                           message: message,
                                           sample_name: sample_name,
                                           service_provider: service.provider.to_s
                                         })
    end
  end
