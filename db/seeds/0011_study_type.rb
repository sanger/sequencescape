study_types = [
  ["Not specified"              , 0, 0],
  ["Synthetic Genomics"         , 1, 1],
  ["Exome Sequencing"           , 0, 1],
  ["Forensic or Paleo-genomics" , 1, 1],
  ["Pooled Clone Sequencing"    , 0, 1],
  ["Gene Regulation Study"      , 1, 1],
  ["Cancer Genomics"            , 1, 1],
  ["Whole Genome Sequencing"    , 1, 1],
  ["Metagenomics"               , 1, 1],
  ["Transcriptome Analysis"     , 1, 1],
  ["Population Genomics"        , 1, 1],
  ["Resequencing"               , 1, 1],
  ["Epigenetics"                , 1, 1],
  ["TraDIS"                     , 0, 1],
  ["Clone Sequencing"           , 0, 1]
]

StudyType.import [ :name, :valid_type, :valid_for_creation ], study_types, :validate => false
