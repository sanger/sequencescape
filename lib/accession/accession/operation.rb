module Accession
  class Operation
    include ActiveModel::Model

    attr_reader :sample, :user, :submission, :accessionable, :delayed

    validate :check_accessionable

    def initialize(user, sample, tags, delayed = false)
      @user = user
      @sample = sample
      @tags = tags
      @delayed = delayed
      @accessionable = Accession::Sample.new(tags, sample)
    end

    def execute
      if valid?
        if delayed?
          Delayed::Job.enqueue SampleAccessioningJob.new(self)
        else
          post
        end
      end
    end

    def post
      @submission = Accession::Submission.new(user, accessionable)
      submission.post
      submission.update_accession_number
    end

    def success?
      return false unless submission.present?
      submission.accessioned?
    end

    def delayed?
      delayed
    end

  private

    def check_accessionable
      unless accessionable.valid?
        accessionable.errors.each do |key, value|
          errors.add key, value
        end
      end
    end
  end
end
