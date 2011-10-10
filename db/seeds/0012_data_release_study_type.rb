DataReleaseStudyType.import(
  [  :name,                          :is_default, :is_assay_type ],
  [
    ["genomic sequencing",           false,       false ],
    ["transcriptomics",              false,       true  ],
    ["other sequencing-based assay", false,       true  ],
    ["genotyping or cytogenetics",   true,        false ]
  ],
  :validate => false
)
