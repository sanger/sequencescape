# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

dr_study_types = [
  ['genomic sequencing', false, false],
  ['transcriptomics',              false,       true],
  ['other sequencing-based assay', false,       true],
  ['genotyping or cytogenetics',   true,        false]
]

dr_study_types.each do |type|
  DataReleaseStudyType.create!(
    name: type[0],
    is_default: type[1],
    is_assay_type: type[2]
  )
end
