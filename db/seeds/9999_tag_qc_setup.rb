rt = RequestType.create!(
  :key                =>"qc_miseq_sequencing",
  :name               =>"MiSeq sequencing QC",
  :workflow           => Submission::Workflow.find_by_key('short_read_sequencing'),
  :asset_type         => 'LibraryTube',
  :order              => 1,
  :initial_state      => 'pending',
  :multiples_allowed  => false,
  :request_class_name => "MiSeqSequencingRequest",
  :morphology         => 0,
  :for_multiplexing   => false,
  :billable           => true,
  :deprecated         => false,
  :no_target_asset    => false
  ) do |rt|
  Pipeline.find_by_name('MiSeq sequencing').request_types << rt
end

tube = BarcodePrinterType.find_by_name('1D Tube')
plate = BarcodePrinterType.find_by_name('96 Well PLate')

purpose_order = [
      {:class=>PlatePurpose,    :name=>'Tag PCR', :barcode_printer_type => plate, :size => 96, :asset_shape => Map::AssetShape.find_by_name('Standard')},
      {:class=>PlatePurpose,    :name=>'Tag PCR-XP', :barcode_printer_type => plate, :size => 96, :asset_shape => Map::AssetShape.find_by_name('Standard')},
      {:class=>Tube::StockMx,   :name=>'Tag Stock-MX', :target_type=>'StockMultiplexedLibraryTube', :barcode_printer_type => tube},
      {:class=>Tube::StandardMx,:name=>'Tag MX', :target_type=>'MultiplexedLibraryTube', :barcode_printer_type => tube},
    ]

shared = {
  :can_be_considered_a_stock_plate => false,
  :default_state => 'pending',
  :cherrypickable_target => false,
  :cherrypick_direction => 'column',
  :barcode_for_tecan => 'ean13_barcode'
}

ActiveRecord::Base.transaction do
  initial = Purpose.find_by_name('Tag Plate')
  purpose_order.inject(initial) do |parent,child_settings|
    child_settings.delete(:class).create(child_settings.merge(shared)).tap do |child|
      parent.child_relationships.create!(:child => child, :transfer_request_type => RequestType.find_by_name('Transfer'))
    end
  end
end

SubmissionTemplate.create!(
  :name => 'MiSeq for TagQC',
  :submission_class_name => 'LinearSubmission',
  :submission_parameters => {
    :request_options=>{
    },
    :request_type_ids_list=>[[rt.id]],
    :workflow_id=>Submission::Workflow.find_by_key('short_read_sequencing').id,
    :info_differential=>Submission::Workflow.find_by_key('short_read_sequencing').id
  },
  :superceded_by_id => -2
)
