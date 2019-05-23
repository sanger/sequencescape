rt = RequestType.create!(
  key: 'qc_miseq_sequencing',
  name: 'MiSeq sequencing QC',
  asset_type: 'LibraryTube',
  order: 1,
  initial_state: 'pending',
  multiples_allowed: false,
  request_class_name: 'MiSeqSequencingRequest',
  morphology: 0,
  for_multiplexing: false,
  billable: true,
  deprecated: false,
  no_target_asset: false
) do |qc_miseq_sequencing|
  Pipeline.find_by(name: 'MiSeq sequencing').request_types << qc_miseq_sequencing
end
RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [11, 25])
