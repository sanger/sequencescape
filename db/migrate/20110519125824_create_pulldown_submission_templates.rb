class CreatePulldownSubmissionTemplates < ActiveRecord::Migration
  SEQUENCING_REQUEST_TYPE_NAMES = [
    "Single ended sequencing",
    "Single ended hi seq sequencing",
    "Paired end sequencing",
    "HiSeq Paired end sequencing"
  ]

  REQUEST_TYPES = [
    'Pulldown WGS',
    'Pulldown SC',
    'Pulldown ISC'
  ]

  def self.up
    ActiveRecord::Base.transaction do
      workflow = Submission::Workflow.find_by_key('short_read_sequencing') or raise StandardError, 'Cannot find Next-gen sequencing workflow'

      REQUEST_TYPES.each do |request_type_name|
        pulldown_request_type = RequestType.find_by_name(request_type_name) or raise StandardError, "Cannot find #{request_type_name.inspect}"

        RequestType.find_each(:conditions => { :name => SEQUENCING_REQUEST_TYPE_NAMES }) do |sequencing_request_type|
          submission                   = MultiplexedSubmission.new
          submission.request_type_ids  = [ pulldown_request_type.id, sequencing_request_type.id ]
          submission.info_differential = workflow.id
          submission.workflow          = workflow

          SubmissionTemplate.new_from_submission("#{request_type_name} - #{sequencing_request_type.name}", submission).save!
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      template_names = []
      SEQUENCING_REQUEST_TYPE_NAMES.each do |sequencing_name|
        REQUEST_TYPES.each do |request_type_name|
          template_names << "#{request_type_name} - #{sequencing_name}"
        end
      end

      SubmissionTemplate.destroy_all([ 'name IN (?)', template_names ])
    end
  end
end
