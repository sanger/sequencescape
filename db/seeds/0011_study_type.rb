study_types = [
  ["Not specified", 0],
  ["Synthetic Genomics", 1],
  ["Exome Sequencing", 0],
  ["Forensic or Paleo-genomics", 1],
  ["Pooled Clone Sequencing", 0],
  ["Gene Regulation Study", 1],
  ["Cancer Genomics", 1],
  ["Whole Genome Sequencing", 1],
  ["Metagenomics", 1],
  ["Transcriptome Analysis", 1],
  ["Population Genomics", 1],
  ["Resequencing", 1],
  ["Epigenetics", 1],
  ["TraDIS", 0],
  ["Clone Sequencing", 0]
]

StudyType.import [ :name, :valid_type ], study_types, :validate => false
