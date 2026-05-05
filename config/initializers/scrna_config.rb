# frozen_string_literal: true

# Stores constants used in pooling and chip loading calculations for samples in the scRNA Core pipeline.
Rails.application.config.scrna_config = {
  # Number of cells required for each sample going into the pool
  required_number_of_cells_per_sample_in_pool: 35_000,
  # Factor accounting for wastage of material when transferring between labware
  wastage_factor: lambda { |number_of_samples_in_pool|
    return 0.75 if number_of_samples_in_pool <= 13

    0.6
  },
  # Fixed wastage volume in microlitres
  wastage_volume: 5.0,
  # Desired concentration of cells per microlitre for chip loading
  desired_chip_loading_concentration: 2400.0,
  # Volume taken for cell counting in microlitres
  volume_taken_for_cell_counting: 10.0,
  # Minimum and maximum total number of samples allowed for cDNA Prep submission
  cdna_prep_minimum_total_number_of_samples: 5,
  cdna_prep_maximum_total_number_of_samples: 96,
  # Minimum and maximum total number of pools allowed for cDNA Prep submission
  cdna_prep_minimum_total_number_of_pools: 1,
  cdna_prep_maximum_total_number_of_pools: 8,
  # Minimum and maximum number of samples allowed in a pool for cDNA Prep Submission
  cdna_prep_minimum_number_of_samples_per_pool: 5,
  cdna_prep_maximum_number_of_samples_per_pool: 25
}.freeze
