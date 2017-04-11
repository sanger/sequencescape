# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015,2016 Genome Research Ltd.

std = RequestPurpose.create!(key: 'standard')
qc = RequestPurpose.create!(key: 'qc')
int = RequestPurpose.create!(key: 'internal')
ctl = RequestPurpose.create!(key: 'control')

RequestType.create!(
  name: 'Create Asset', key: 'create_asset', order: 1,
  asset_type: 'Asset', multiples_allowed: false,
  request_class_name: 'CreateAssetRequest', morphology: RequestType::LINEAR,
  request_purpose: int
)
RequestType.create!(
  name: 'Transfer', key: 'transfer', order: 1,
  asset_type: 'Asset', multiples_allowed: false,
  request_class_name: 'TransferRequest', morphology: RequestType::CONVERGENT,
  for_multiplexing: 0, billable: 0,
  request_purpose: int
)
RequestType.create!(
  key: 'initial_pacbio_transfer',
  name: 'Initial Pacbio Transfer',
  asset_type: 'Well',
  request_class_name: 'PacBioSamplePrepRequest::Initial',
  order: 1,
  request_purpose: int
)
RequestType.create!(
  name: 'Initial Transfer', key: 'initial_transfer', order: 1,
  asset_type: 'Asset', multiples_allowed: false,
  request_class_name: 'TransferRequest::InitialTransfer', morphology: RequestType::CONVERGENT,
  for_multiplexing: 0, billable: 0,
  request_purpose: int
)
RequestType.create!(
  asset_type: 'LibraryTube',
  billable: false,
  deprecated: false,
  for_multiplexing: true,
  initial_state: 'pending',
  key: 'external_multiplexed_library_creation',
  morphology: 0,
  order: 0,
  multiples_allowed: false,
  name: 'External Multiplexed Library Creation',
  no_target_asset: false,
  request_class_name: 'ExternalLibraryCreationRequest',
  request_purpose: std
)
