class AddXtenSubmissionTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      new_st = SubmissionTemplate.create!(
        :name => "HiSeq-X sequencing",
        :submission_class_name => 'FlexibleSubmission',
        :submission_parameters => {
          :order_role_id => Order::OrderRole.find_or_create_by_role('HSqX'),
          :request_type_ids_list => request_types,
          :workflow_id => Submission::Workflow.find_by_key("short_read_sequencing").id
        },
        :product_line_id => ProductLine.find_by_name!('Illumina-B').id
      )
      SubmissionTemplate.find_by_name('Illumina-C - General PCR - HiSeq-X sequencing').try(:update_attributes!,{
        :superceded_by => new_st,
        :superceded_at => Time.now
      })
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name!("HiSeq-X sequencing").destroy
      SubmissionTemplate.find_by_name!('Illumina-C - General PCR - HiSeq-X sequencing').update_attributes!(
        :superceded_by => SubmissionTemplate::LATEST_VERSION,
        :superceded_at => nil
      )
    end
  end

  def self.request_types
    [
      'illumina_b_shared',
      'illumina_htp_library_creation',
      'illumina_htp_strip_tube_creation',
      'illumina_b_hiseq_x_paired_end_sequencing'
    ].map {|key| [RequestType.find_by_key!(key).id]}
  end
end
