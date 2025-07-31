# frozen_string_literal: true

require 'exception_notification'

# Sends sample data to the ENA or EGA in order to generate an accession number
# Records the generated accession number on the sample
# @see Accession::Submission
SampleAccessioningJob =
  Struct.new(:accessionable) do
    def perform
      submission = Accession::Submission.new(User.find_by(api_key: configatron.accession_local_key), accessionable)
      submission.post

      # update_accession_number returns true if an accession has been supplied, and the sample has been saved.
      # If this returns false, then we fail the job. This should catch any failure situations
      cause = 'EBI failed to update accession number, data may be invalid'

      submission.update_accession_number || raise_accession_error(submission, cause)
    rescue AccessionService::AccessionServiceError => e
      handle_accession_error(e, submission, cause)
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

    def raise_accession_error(submission, cause)
      sample_id = submission.sample.sanger_sample_id
      user = submission.user
      message = "SampleAccessioningJob failed for sample '#{sample_id}' by user '#{user.username}' (#{user.id}): #{cause}"

      raise(AccessionService::AccessionServiceError, message)
    end

    def handle_accession_error(error, submission, cause)
      sample_id = submission.sample.sanger_sample_id
      user = submission.user
      service = submission.service

      Rails.logger.error(job_error_message)
      ExceptionNotifier.notify_exception(error, data: {
                                           cause_message: cause,
                                           sample_id: sample_id,
                                           user_id: user.id,
                                           user_username: user.username,
                                           service: service.name
                                         })
    end
  end
