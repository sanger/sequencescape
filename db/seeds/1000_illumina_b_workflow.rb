ActiveRecord::Base.transaction do

  IlluminaB::PlatePurposes.create_tube_purposes

  workflow   = Submission::Workflow.find_by_key('short_read_sequencing') or raise StandardError, 'Cannot find Next-gen sequencing workflow'
  cherrypick = RequestType.find_by_name('Cherrypicking for Pulldown')    or raise StandardError, 'Cannot find Cherrypicking for Pulldown request type'

  pipeline_name = "Illumina-B STD"

  shared_options = {
        :workflow => workflow,
        :asset_type => "Well",
        :order => 1,
        :initial_state => "pending",
        :billable => true,
        :product_line_id => ProductLine.find_by_name('Illumina-B'),
        :no_target_asset => false
  }

  [
    {
      :name              => "Illumina-B STD",
      :key               => pipeline_name.downcase.gsub(/\W+/, '_'),
      :target_purpose    => Tube::Purpose.find_by_name!('ILB_STD_MX'),
      :request_class_name     => "IlluminaB::Requests::StdLibraryRequest"
    },
    {
      :key => "illumina_b_shared",
      :name => "Shared Library Creation",
      :request_class_name => "IlluminaB::Requests::SharedLibraryPrep",
      :for_multiplexing => false,
      :no_target_asset => false
    },
    {
      :key => "illumina_b_pool",
      :name => "Illumina-B Pooled",
      :request_class_name => "IlluminaB::Requests::LibraryCompletion",
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name('Lib Pool Norm')
    },
    {
      :key => "illumina_b_pippin",
      :name => "Illumina-B Pippin",
      :request_class_name => "IlluminaB::Requests::LibraryCompletion",
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name('Lib Pool SS-XP-Norm')
    },
  ].each do |request_type_options|
    RequestType.create!(shared_options.merge(request_type_options))
  end

  IlluminaB::PlatePurposes.create_plate_purposes
  IlluminaB::PlatePurposes.create_branches

  sequencing_request_type_names = [
    "Single ended sequencing",
    "Single ended hi seq sequencing",
    "Paired end sequencing",
    "HiSeq Paired end sequencing",
    "HiSeq 2500 Single end sequencing",
    "HiSeq 2500 Paired end sequencing"
  ]

  [
    {:pulldown_requests=>["Illumina-B STD"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Multiplexed WGS'},
    {:pulldown_requests=>["Shared Library Creation","Illumina-B Pooled"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Pippin'},
    {:pulldown_requests=>["Shared Library Creation","Illumina-B Pippin"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Pooled'}
  ].each do |request_type_options|
    defaults = request_type_options[:defaults]
    pulldown_request_types = request_type_options[:pulldown_requests].map do |request_type_name|
      RequestType.find_by_name!(request_type_name)
    end

    RequestType.find_each(:conditions => { :name => sequencing_request_type_names }) do |sequencing_request_type|
      submission                   = LinearSubmission.new
      submission.request_type_ids  = [ cherrypick.id, pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten
      submission.info_differential = workflow.id
      submission.workflow          = workflow
      submission.request_options   = defaults

      SubmissionTemplate.new_from_submission(
        "Illumina-B - Cherrypicked - #{request_type_options[:name]} - #{sequencing_request_type}",
        submission
      ).save!

      submission.request_type_ids  = [ pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten

      SubmissionTemplate.new_from_submission(
        "Illumina-B - #{request_type_options[:name]} - #{sequencing_request_type}",
        submission
      ).save!
    end
  end
end
