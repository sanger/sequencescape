dr_study_types = [
    ["genomic sequencing",           false,       false ],
    ["transcriptomics",              false,       true  ],
    ["other sequencing-based assay", false,       true  ],
    ["genotyping or cytogenetics",   true,        false ]
  ]

dr_study_types.each do |type|
  DataReleaseStudyType.create!(
    :name => type[0],
    :is_default => type[1],
    :is_assay_type => type[2]
  )
end
