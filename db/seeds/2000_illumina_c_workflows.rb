#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014 Genome Research Ltd.
ActiveRecord::Base.transaction do
  IlluminaC::PlatePurposes.create_plate_purposes
  IlluminaC::PlatePurposes.create_tube_purposes
  IlluminaC::PlatePurposes.create_branches
  IlluminaC::Requests.create_request_types

  [
    {:name=>'General PCR',     :role=>'PCR',      :type=>'illumina_c_pcr'},
    {:name=>'General no PCR',  :role=>'No PCR',   :type=>'illumina_c_nopcr'},
    {:name=>'Multiplex',     :role=>'PCR',        :type=>'illumina_c_multiplexing',:skip_cherrypick => true}
  ].each do |options|
    IlluminaC::Helper::TemplateConstructor.new(options).build!
  end

  SubmissionTemplate.create!(
    :name => 'Illumina-C - General PCR - No multiplexing',
    :submission_class_name => 'LinearSubmission',
    :product_line => ProductLine.find_by_name('Illumina-C'),
    :submission_parameters => {
      :request_type_ids_list => [[RequestType.find_by_key('illumina_c_pcr_no_pool').id]],
      :workflow_id => Submission::Workflow.find_by_key('short_read_sequencing').id,
      :order_role_id => Order::OrderRole.find_by_role('PCR').id,
      :info_differential => 1
    }
  )
end
