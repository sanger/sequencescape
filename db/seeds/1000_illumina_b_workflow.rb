#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.
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

  tube_purpose = Tube::Purpose.find_by_name('Cap Lib Pool Norm') or raise "Cannot find standard MX tube purpose"
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
      :key => "illumina_a_pool",
      :name => "Illumina-A Pooled",
      :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name!('Lib Pool Norm')
    },
    {
      :key => "illumina_a_isc",
      :name => "Illumina-A ISC",
      :request_class_name => "Pulldown::Requests::IscLibraryRequestPart",
      :acceptable_plate_purposes => [Purpose.find_by_name('Lib PCR-XP')],
      :for_multiplexing => true,
      :no_target_asset => false,
      :target_purpose => Purpose.find_by_name('Cap Lib Pool Norm')
    }
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
        "Illumina-B - Cherrypicked - #{request_type_options[:name]} - #{sequencing_request_type.name.gsub(/Illumina-[ABC] /,'')}",
        submission
      )
      st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id}) unless request_type_options[:label].nil?
      st.save!

      submission.request_type_ids  = [ pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten

      st = SubmissionTemplate.new_from_submission(
        "Illumina-B - #{request_type_options[:name]} - #{sequencing_request_type.name.gsub(/Illumina-[ABC] /,'')}",
        submission
      )
      st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id}) unless request_type_options[:label].nil?
      st.save!
    end
  end

  [
    {:pulldown_requests=>["Illumina-A Shared Library Creation","Illumina-A ISC"], :defaults=>{ 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500, 'pre_capture_plex_level' => "8" }, :name=>'HTP ISC', :label=>'ILA ISC'}
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
        "Illumina-A - Cherrypicked - #{request_type_options[:name]} - #{sequencing_request_type.name.gsub(/Illumina-[ABC] /,'')}",
        submission
      )
      st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id})
      st.save!

      submission.request_type_ids  = [ pulldown_request_types.map(&:id), sequencing_request_type.id ].flatten

      st = SubmissionTemplate.new_from_submission(
        "Illumina-A - #{request_type_options[:name]} - #{sequencing_request_type.name.gsub(/Illumina-[ABC] /,'')}",
        submission
      )
       st.submission_parameters.merge!({:order_role_id=>Order::OrderRole.find_or_create_by_role(request_type_options[:label]).id})
      st.save!
    end
  end
  IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST.each do |purpose,request|
    RequestType.find_by_key(request).acceptable_plate_purposes << Purpose.find_by_name(purpose)
  end

re_request = RequestType.create!(
    :key=>'illumina_a_re_isc',
    :name=>'Illumina-A ReISC',
    :workflow=>workflow,
    :asset_type => 'Well',
    :initial_state => 'pending',
    :order=>1,
    :request_class_name => 'Pulldown::Requests::IscLibraryRequest',
    :for_multiplexing => true,
    :product_line => ProductLine.find_by_name('Illumina-A'),
    :target_purpose => Purpose.find_by_name('Standard MX')
  ) do |rt|
    rt.acceptable_plate_purposes << PlatePurpose.find_by_name!('Lib PCR-XP')
     RequestType::Validator.create!(:request_type=>rt, :request_option=> "library_type", :valid_options=>RequestType::Validator::LibraryTypeValidator.new(rt.id))
  end
  [
    'illumina_a_hiseq_paired_end_sequencing',
    'illumina_a_single_ended_hi_seq_sequencing',
    'illumina_a_hiseq_2500_paired_end_sequencing',
    'illumina_a_hiseq_2500_single_end_sequencing',
    'illumina_a_miseq_sequencing',
    'illumina_a_hiseq_v4_paired_end_sequencing',
    'illumina_a_hiseq_x_paired_end_sequencing'
  ].each do |sequencing_key|
      sequencing_request = RequestType.find_by_key!(sequencing_key)
      SubmissionTemplate.create!(
          :name => "ISC Repool - #{sequencing_request.name.gsub('Illumina-A ','')}",
          :submission_class_name => 'LinearSubmission',
          :submission_parameters => {
            :request_type_ids_list => [[re_request.id],[sequencing_request.id]],
            :workflow_id => Submission::Workflow.find_by_key('short_read_sequencing').id,
            :order_role_id => Order::OrderRole.find_or_create_by_role('ReISC').id,
            :request_options => {'pre_capture_plex_level'=>8}
          },
          :product_line => ProductLine.find_by_name('Illumina-A')
        )
    end


  RequestType.create!(
    :name => "Illumina-HTP Library Creation",
    :key => "illumina_htp_library_creation",
    :workflow => Submission::Workflow.find_by_key!("short_read_sequencing"),
    :asset_type => "Well",
    :order => 1,
    :initial_state => "pending",
    :multiples_allowed => false,
    :request_class_name => "IlluminaHtp::Requests::LibraryCompletion",
    :morphology => 0,
    :for_multiplexing => true,
    :billable => false,
    :product_line => ProductLine.find_by_name!("Illumina-B")
    ) do |rt|
      rt.pooling_method = RequestType::PoolingMethod.create!(
          :pooling_behaviour => 'PlateRow',
          :pooling_options   => {:pool_count=>8}
        )
    end

    RequestType.create!(
      :name => 'Illumina-HTP Strip Tube Creation',
      :key  => 'illumina_htp_strip_tube_creation',
      :workflow => Submission::Workflow.find_by_key!("short_read_sequencing"),
      :asset_type => "Well",
      :order => 2,
      :initial_state => "pending",
      :multiples_allowed => true,
      :request_class_name => "StripCreationRequest",
      :for_multiplexing => false,
      :billable => false,
      :product_line => ProductLine.find_by_name!("Illumina-B")
    )

      RequestType.find_by_key!('illumina_b_hiseq_x_paired_end_sequencing').acceptable_plate_purposes << PlatePurpose.create!(
        :name        =>'Strip Tube Purpose',
        :target_type => 'StripTube',
        :can_be_considered_a_stock_plate => false,
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :barcode_printer_type =>  BarcodePrinterType.find_by_name("96 Well Plate"),
        :cherrypick_direction => 'column',
        :size => 8,
        :asset_shape => Map::AssetShape.find_by_name('StripTubeColumn'),
        :barcode_for_tecan => 'ean13_barcode'
      )
end

StripTubeCreationPipeline.create!(
  :name => 'Strip Tube Creation',
  :automated => false,
  :active => true,
  :location => Location.find_by_name('Cluster formation freezer'),
  :group_by_parent => true,
  :sorter => 8,
  :paginate => false,
  :max_size => 96,
  :min_size => 8,
  :summary => true,
  :externally_managed => false,
  :control_request_type_id => 0,
  :group_name => 'Sequencing'
) do |pipeline|
  pipeline.request_types << RequestType.find_by_key!('illumina_htp_strip_tube_creation')
  pipeline.workflow = LabInterface::Workflow.create!(:name=>'Strip Tube Creation').tap do |workflow|
    stct = StripTubeCreationTask.create!(
      :name => 'Strip Tube Creation',
      :workflow => workflow,
      :sorted => 1,
      :interactive => true,
      :lab_activity => true
    )
    stct.descriptors.create!(
      :name => 'Strips to create',
      :selection => [1,2,4,6,12],
      :kind => 'Selection',
      :key => 'strips_to_create'
    )
    stct.descriptors.create!(
      :name => 'Strip Tube Purpose',
      :value => 'Strip Tube Purpose',
      :key => 'strip_tube_purpose'
    )
  end

end
