# frozen_string_literal: true
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
      submission.update_accession_number || raise(StandardError)
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
