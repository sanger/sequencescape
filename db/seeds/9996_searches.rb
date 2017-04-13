# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

# Here are a load of searches that can be performed through the API.
Search::FindAssetByBarcode.create!(name: 'Find assets by barcode')
Search::FindModelByName.create!(name: 'Find project by name', target_model_name: 'Project')
Search::FindModelByName.create!(name: 'Find study by name',   target_model_name: 'Study')
Search::FindModelByName.create!(name: 'Find sample by name',  target_model_name: 'Sample')
Search::FindSourceAssetsByDestinationAssetBarcode.create!(name: 'Find source assets by destination asset barcode')
Search::FindUserByLogin.create!(name: 'Find user by login')
Search::FindUserBySwipecardCode.create!(name: 'Find user by swipecard code')
Search::FindPulldownPlates.create!(name: 'Find pulldown plates')
Search::FindIlluminaBPlates.create!(name: 'Find Illumina-B plates')
Search::FindIlluminaBPlatesForUser.create!(name: 'Find Illumina-B plates for user')
Search::FindIlluminaBStockPlates.create!(name: 'Find Illumina-B stock plates')
Search::FindOutstandingIlluminaBPrePcrPlates.create!(name: 'Find outstanding Illumina-B pre-PCR plates')
Search::FindPulldownPlatesForUser.create!(name: 'Find pulldown plates for user')
Search::FindPulldownStockPlates.create!(name: 'Find pulldown stock plates')
Search::FindIlluminaAPlates.create!(name: 'Find Illumina-A plates')
Search::FindIlluminaAStockPlates.create!(name: 'Find Illumina-A stock plates')
Search::FindIlluminaCTubes.create!(name: 'Find Illumina-C tubes')
Search::FindIlluminaCPlates.create!(name: 'Find Illumina-C plates')
Search::FindLotByLotNumber.create!(name: 'Find lot by lot number')
Search::FindQcableByBarcode.create!(name: 'Find qcable by barcode')
Search::FindRobotByBarcode.create!(name: 'Find robot by barcode')
Search::FindLotByBatchId.create!(name: 'Find lot by batch id')
plate_purposes = Purpose.where(name: ['ILC Stock',
      'ILC AL Libs',
      'ILC Lib PCR',
      'ILC Lib PCR-XP',
      'ILC AL Libs Tagged']).pluck(:id)
Search::FindPlatesForUser.create!(name: 'Find Illumina-C plates for user', default_parameters: { plate_purpose_ids: plate_purposes, limit: 30, include_used: true })
