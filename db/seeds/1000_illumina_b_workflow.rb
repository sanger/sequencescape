ActiveRecord::Base.transaction do
  IlluminaB::PlatePurposes.create_tube_purposes

  workflow   = Submission::Workflow.find_by_key('short_read_sequencing') or raise StandardError, 'Cannot find Next-gen sequencing workflow'
  cherrypick = RequestType.find_by_name('Cherrypicking for Pulldown')    or raise StandardError, 'Cannot find Cherrypicking for Pulldown request type'

  pipeline_name = "Illumina-B STD"
  Pipeline.create!(:name => pipeline_name) do |pipeline|
    pipeline.sorter             = Pipeline.maximum(:sorter) + 1
    pipeline.automated          = false
    pipeline.active             = true
    pipeline.asset_type         = 'LibraryTube'
    pipeline.externally_managed = true

    pipeline.location = Location.first(:conditions => { :name => 'Library creation freezer' }) or raise StandardError, "Cannot find 'Library creation freezer' location"

    pipeline.request_types << RequestType.create!(:workflow => workflow, :name => pipeline_name) do |request_type|
      request_type.billable          = true
      request_type.key               = pipeline_name.downcase.gsub(/\W+/, '_')
      request_type.initial_state     = 'pending'
      request_type.asset_type        = 'Well'
      request_type.target_purpose    = Tube::Purpose.find_by_name('ILB_STD_MX') or raise "Cannot find ILB_STD_MX tube purpose"
      request_type.order             = 1
      request_type.multiples_allowed = false
      request_type.request_class     = IlluminaB::Requests::StdLibraryRequest
      request_type.for_multiplexing  = true
      request_type.product_line = ProductLine.find_by_name('Illumina-B')
    end

    pipeline.workflow = LabInterface::Workflow.create!(:name => pipeline_name)
  end

  IlluminaB::PlatePurposes.create_plate_purposes
  IlluminaB::PlatePurposes.create_branches

  sequencing_request_type_names = [
    "Single ended sequencing",
    "Single ended hi seq sequencing",
    "Paired end sequencing",
    "HiSeq Paired end sequencing"
  ]

  {
    'Illumina-B STD' => { 'library_type' => 'Standard', 'fragment_size_required_from' => 300, 'fragment_size_required_to' => 500 }
  }.each do |request_type_name, defaults|
    pulldown_request_type = RequestType.find_by_name(request_type_name) or raise StandardError, "Cannot find #{request_type_name.inspect}"

    RequestType.find_each(:conditions => { :name => sequencing_request_type_names }) do |sequencing_request_type|
      submission                   = LinearSubmission.new
      submission.request_type_ids  = [ cherrypick.id, pulldown_request_type.id, sequencing_request_type.id ]
      submission.info_differential = workflow.id
      submission.workflow          = workflow
      submission.request_options   = defaults

      SubmissionTemplate.new_from_submission(
        "Cherrypick for pulldown - #{request_type_name} - #{sequencing_request_type.name}",
        submission
      ).tap { |template| template.superceded_by_unknown! }.save!

      SubmissionTemplate.new_from_submission(
        "Illumina-B - Cherrypicked - Multiplexed WGS - #{sequencing_request_type.name}",
        submission
      ).save!

      submission.request_type_ids  = [ pulldown_request_type.id, sequencing_request_type.id ]

      SubmissionTemplate.new_from_submission(
        "Illumina-B - Multiplexed WGS - #{sequencing_request_type.name}",
        submission
      ).save!
    end
  end
end
