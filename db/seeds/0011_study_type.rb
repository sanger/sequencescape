# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

study_types = [
  ['Not specified', 0, 0],
  ['Synthetic Genomics', 1, 1],
  ['Exome Sequencing', 0, 1],
  ['Forensic or Paleo-genomics', 1, 1],
  ['Pooled Clone Sequencing', 0, 1],
  ['Gene Regulation Study', 1, 1],
  ['Cancer Genomics', 1, 1],
  ['Whole Genome Sequencing', 1, 1],
  ['Metagenomics', 1, 1],
  ['Transcriptome Analysis', 1, 1],
  ['Population Genomics', 1, 1],
  ['Resequencing', 1, 1],
  ['Epigenetics', 1, 1],
  ['TraDIS', 0, 1],
  ['Clone Sequencing', 0, 1]
]

study_types.each do |type|
  StudyType.create(name: type[0], valid_type: type[1], valid_for_creation: type[2])
end

# Other study related configuration
Program.create!(name: 'General').save
