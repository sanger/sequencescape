# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015,2016 Genome Research Ltd.

rt = rt = RequestType.find_by(key: 'qc_miseq_sequencing')
tube = BarcodePrinterType.find_by(name: '1D Tube')
plate = BarcodePrinterType.find_by(name: '96 Well PLate')

purpose_order = [
      { class: QcableLibraryPlatePurpose, name: 'Tag PCR', barcode_printer_type: plate, size: 96, asset_shape: AssetShape.find_by(name: 'Standard') },
      { class: PlatePurpose,    name: 'Tag PCR-XP', barcode_printer_type: plate, size: 96, asset_shape: AssetShape.find_by(name: 'Standard') },
      { class: Tube::StockMx,   name: 'Tag Stock-MX', target_type: 'StockMultiplexedLibraryTube', barcode_printer_type: tube },
      { class: Tube::StandardMx, name: 'Tag MX', target_type: 'MultiplexedLibraryTube', barcode_printer_type: tube },
    ]

shared = {
  stock_plate: false,
  default_state: 'pending',
  cherrypickable_target: false,
  cherrypick_direction: 'column',
  barcode_for_tecan: 'ean13_barcode'
}

ActiveRecord::Base.transaction do
  initial = Purpose.find_by(name: 'Tag Plate')
  purpose_order.inject(initial) do |parent, child_settings|
    child_settings.delete(:class).create(child_settings.merge(shared)).tap do |child|
      parent.child_relationships.create!(child: child, transfer_request_type: RequestType.find_by(name: 'Transfer'))
    end
  end
  Purpose::Relationship.create!(parent: Purpose.find_by(name: 'Reporter Plate'), child: Purpose.find_by(name: 'Tag PCR'), transfer_request_type: RequestType.transfer)
  Purpose::Relationship.create!(parent: Purpose.find_by(name: 'Pre Stamped Tag Plate'), child: Purpose.find_by(name: 'Tag PCR'), transfer_request_type: RequestType.transfer)
end

mi_seq_freezer = Location.find_by(name: 'MiSeq freezer')
SequencingPipeline.create!(name: 'MiSeq sequencing QC') do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = mi_seq_freezer

  pipeline.request_types << rt

  pipeline.workflow = LabInterface::Workflow.create!(name: 'MiSeq sequencing QC') do |workflow|
    workflow.locale     = 'External'
    workflow.item_limit = 1
  end.tap do |workflow|
      t1 = SetDescriptorsTask.create!(name: 'Specify Dilution Volume', sorted: 0, workflow: workflow)
      Descriptor.create!(kind: 'Text', sorter: 1, name: 'Concentration', task: t1)
      t2 = SetDescriptorsTask.create!(name: 'Cluster Generation', sorted: 0, workflow: workflow)
      Descriptor.create!(kind: 'Text', sorter: 1, name: 'Chip barcode', task: t2)
      Descriptor.create!(kind: 'Text', sorter: 2, name: 'Cartridge barcode', task: t2)
      Descriptor.create!(kind: 'Text', sorter: 3, name: 'Operator', task: t2)
      Descriptor.create!(kind: 'Text', sorter: 4, name: 'Machine name', task: t2)
  end
end.tap do |pipeline|
  create_request_information_types(pipeline, 'fragment_size_required_from', 'fragment_size_required_to', 'library_type', 'read_length')
end

SubmissionTemplate.create!(
  name: 'MiSeq for TagQC',
  submission_class_name: 'LinearSubmission',
  submission_parameters: {
    request_options: {
    },
    request_type_ids_list: [[rt.id]],
    workflow_id: Submission::Workflow.find_by(key: 'short_read_sequencing').id,
    info_differential: Submission::Workflow.find_by(key: 'short_read_sequencing').id
  },
  superceded_by_id: -2,
  product_catalogue: ProductCatalogue.find_by(name: 'Generic')
)
SubmissionTemplate.create!(
  name: 'MiSeq for QC',
  submission_class_name: 'LinearSubmission',
  submission_parameters: {
    request_options: {
    },
    request_type_ids_list: [[rt.id]],
    workflow_id: Submission::Workflow.find_by(key: 'short_read_sequencing').id,
    info_differential: Submission::Workflow.find_by(key: 'short_read_sequencing').id
  },
  superceded_by_id: -2,
  product_catalogue: ProductCatalogue.find_by(name: 'Generic')
)
