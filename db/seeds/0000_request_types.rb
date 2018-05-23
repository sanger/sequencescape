# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015,2016 Genome Research Ltd.

RequestType.create_asset

RequestType.create!(
  asset_type: 'LibraryTube',
  for_multiplexing: true,
  initial_state: 'pending',
  key: 'external_multiplexed_library_creation',
  order: 0,
  name: 'External Multiplexed Library Creation',
  request_class_name: 'ExternalLibraryCreationRequest',
  request_purpose: :standard
)
