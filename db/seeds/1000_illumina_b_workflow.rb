ActiveRecord::Base.transaction do


  workflow   = Submission::Workflow.find_by_key('short_read_sequencing') or raise StandardError, 'Cannot find Next-gen sequencing workflow'
  cherrypick = RequestType.find_by_name('Cherrypicking for Pulldown')    or raise StandardError, 'Cannot find Cherrypicking for Pulldown request type'

  pipeline_name = "Illumina-B STD"

  IlluminaB::PlatePurposes.create_tube_purposes
  IlluminaHtp::PlatePurposes.create_tube_purposes

  # For B
  shared_options_b = {
        :workflow => workflow,
        :asset_type => "Well",
        :order => 1,
        :initial_state => "pending",
        :billable => true,
        :product_line_id => ProductLine.find_by_name('Illumina-B'),
        :no_target_asset => false
  }

  shared_options_a = shared_options_b.clone.merge({:product_line_id => ProductLine.find_by_name('Illumina-A')})

  [
    {
      :name               => "Illumina-B STD",
      :key                => pipeline_name.downcase.gsub(/\W+/, '_'),
      :target_purpose     => Tube::Purpose.find_by_name!('ILB_STD_MX'),
      :for_multiplexing   => true,
      :request_class_name => "IlluminaB::Requests::StdLibraryRequest"
    },
    {
      :key => "illumina_b_shared",
      :name => "Shared Library Creation",
      :request_class_name => "IlluminaHtp::Requests::SharedLibraryPrep",
      :for_multiplexing => false,
      :no_target_asset => false
    },
    {
      :key => "illumina_b_pool",
      :name => "Illumina-B Pooled",
      :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name!('Lib Pool Norm')
    },
    {
      :key => "illumina_b_pippin",
      :name => "Illumina-B Pippin",
      :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name!('Lib Pool SS-XP-Norm')
    },
  ].each do |request_type_options|
    RequestType.create!(shared_options_b.merge(request_type_options))
  end

  IlluminaB::PlatePurposes.create_plate_purposes
  IlluminaB::PlatePurposes.create_branches
  IlluminaHtp::PlatePurposes.create_plate_purposes
  IlluminaHtp::PlatePurposes.create_branches

  Pulldown::PlatePurposes.create_purposes(Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.last)

  tube_purpose = Tube::Purpose.find_by_name('Standard MX') or raise "Cannot find standard MX tube purpose"
  Purpose.find_by_name(Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.last.last).child_relationships.create!(:child => tube_purpose, :transfer_request_type => RequestType.transfer)


  [
    {
      :key => "illumina_a_shared",
      :name => "Illumina-A Shared Library Creation",
      :request_class_name => "IlluminaHtp::Requests::SharedLibraryPrep",
      :acceptable_plate_purposes => [Purpose.find_by_name('Cherrypicked')],
      :for_multiplexing => false,
      :no_target_asset => false
    },
    {
      :key => "illumina_a_isc",
      :name => "Illumina-A ISC",
      :request_class_name => "Pulldown::Requests::IscLibraryRequestPart",
      :acceptable_plate_purposes => [Purpose.find_by_name('Lib PCR-XP')],
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name('Standard MX')
    },
    {
      :key => "illumina_a_pool",
      :name => "Illumina-A Pooled",
      :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name!('Lib Pool Norm')
    },
  ].each do |request_type_options|
    RequestType.create!(shared_options_a.merge(request_type_options))
  end


  sequencing_request_type_names = [
    "Single ended sequencing",
    "Single ended hi seq sequencing",
    "Paired end sequencing",
    "HiSeq Paired end sequencing",
    "HiSeq 2500 Single end sequencing",
    "HiSeq 2500 Paired end sequencing"
  ]

  def sequencing_request_type_names_for(pipeline)
    [
    "Single ended sequencing",
    "Single ended hi seq sequencing",
    "Paired end sequencing",
    "HiSeq Paired end sequencing",
    "HiSeq 2500 Single end sequencing",
    "HiSeq 2500 Paired end sequencing"
  ].map {|s| "#{pipeline} #{s}"}
  end

  [
    {:pulldown_requests=>["Illumina-B STD"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Multiplexed WGS'},
    {:pulldown_requests=>["Shared Library Creation","Illumina-B Pooled"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Pooled PATH', :label=>'ILB PATH'},
    {:pulldown_requests=>["Shared Library Creation","Illumina-B Pippin"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Pippin PATH', :label=>'ILB PATH'},
    {:pulldown_requests=>["Shared Library Creation","Illumina-B Pooled"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Pooled HWGS', :label=>'ILB HWGS'},
    {:pulldown_requests=>["Shared Library Creation","Illumina-B Pippin"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Pippin HWGS', :label=>'ILB HWGS'}
  ].each do |request_type_options|
    defaults = request_type_options[:defaults]
    pulldown_request_types = request_type_options[:pulldown_requests].map do |request_type_name|
      RequestType.find_by_name!(request_type_name)
    end

    RequestType.find_each(:conditions => { :name => sequencing_request_type_names_for('Illumina-B') }) do |sequencing_request_type|
      submission                   = LinearSubmission.new
      submission.request_type_ids  = [ cherrypick.id, pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten
      submission.info_differential = workflow.id
      submission.workflow          = workflow
      submission.request_options   = defaults

      st = SubmissionTemplate.new_from_submission(
        "Illumina-B - Cherrypicked - #{request_type_options[:name]} - #{sequencing_request_type.name}",
        submission
      )
      st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id}) unless request_type_options[:label].nil?
      st.save!

      submission.request_type_ids  = [ pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten

      st = SubmissionTemplate.new_from_submission(
        "Illumina-B - #{request_type_options[:name]} - #{sequencing_request_type.name}",
        submission
      )
      st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id}) unless request_type_options[:label].nil?
      st.save!
    end
  end

  [
    {:pulldown_requests=>["Illumina-A Shared Library Creation","Illumina-A ISC"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500, 'pre_capture_plex_level' => "8" }, :name=>'HTP ISC', :label=>'ILA ISC'},
    {:pulldown_requests=>["Illumina-A Shared Library Creation","Illumina-A Pooled"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }, :name=>'Pooled', :label=>'ILA'}
  ].each do |request_type_options|
    defaults = request_type_options[:defaults]
    pulldown_request_types = request_type_options[:pulldown_requests].map do |request_type_name|
      RequestType.find_by_name!(request_type_name)
    end

    RequestType.find_each(:conditions => { :name => sequencing_request_type_names_for('Illumina-A') }) do |sequencing_request_type|
      submission                   = LinearSubmission.new
      submission.request_type_ids  = [ cherrypick.id, pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten
      submission.info_differential = workflow.id
      submission.workflow          = workflow
      submission.request_options   = defaults

      st = SubmissionTemplate.new_from_submission(
        "Illumina-A - Cherrypicked - #{request_type_options[:name]} - #{sequencing_request_type.name}",
        submission
      )
      st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id})
      st.save!

      submission.request_type_ids  = [ pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten

      st = SubmissionTemplate.new_from_submission(
        "Illumina-A - #{request_type_options[:name]} - #{sequencing_request_type.name}",
        submission
      )
       st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id})
      st.save!
    end
  end
  IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST.each do |purpose,request|
    RequestType.find_by_key(request).acceptable_plate_purposes << Purpose.find_by_name(purpose)
  end
end
