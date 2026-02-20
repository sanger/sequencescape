# frozen_string_literal: true

# This configuration was copied from Limber and modified with additional entries
# for the scRNA Core cDNA Prep submission.
# Stores constants used in pooling and chip loading calculations for samples in the scRNA Core pipeline.
Rails.application.config.scrna_config = {
  # Maximum volume to take into the pools plate for each sample (in microlitres)
  maximum_sample_volume: 70.0,
  # Minimum volume to take into the pools plate for each sample (in microlitres)
  minimum_sample_volume: 5.0,
  # Minimum volume required for resuspension in microlitres
  minimum_resuspension_volume: 10.0,
  # Conversion factor from millilitres to microlitres
  millilitres_to_microlitres: 1_000.0,
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
  # Desired volume in the chip well (in microlitres)
  desired_chip_loading_volume: 37.5,
  # Desired number of runs for full allowance calculations
  desired_number_of_runs: 2,
  # Volume taken for cell counting in microlitres
  volume_taken_for_cell_counting: 10.0,
  # Key for the required number of cells metadata stored on Study (in poly_metadata)
  study_required_number_of_cells_per_sample_in_pool_key: 'scrna_core_pbmc_donor_pooling_required_number_of_cells',
  # Default viability threshold when passing/failing samples (in percent)
  viability_default_threshold: 50,
  # Default total cell count threshold when passing/failing samples
  total_cell_count_default_threshold: 50_000,
  # Key for the number of cells per chip well metadata stored on pool wells (in poly_metadata)
  number_of_cells_per_chip_well_key: 'scrna_core_pbmc_donor_pooling_number_of_cells_per_chip_well',
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
