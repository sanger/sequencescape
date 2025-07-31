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
      sample_id = accessionable.sample.sanger_sample_id
      user = submission.user
      cause = 'EBI failed to update accession number, data may be invalid'
      message = "SampleAccessioningJob failed for sample '#{sample_id}' by user '#{user.username}' (#{user.id}): #{cause}"

      submission.update_accession_number || raise(AccessionService::AccessionServiceError, message)
    rescue AccessionService::AccessionServiceError => e
      Rails.logger.error(job_error_message)
      ExceptionNotifier.notify_exception(e, data: {
                                           cause_message: cause,
                                           sample_id: sample_id,
                                           user_id: user.id,
                                           user_username: user.username,
                                           job_class: self.class.name,
                                           job_id: jid,
                                           accessionable_id: accessionable.id,
                                           accessionable_type: accessionable.class.name
                                         })
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
  end
