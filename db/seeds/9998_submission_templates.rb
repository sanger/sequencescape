# frozen_string_literal: true

# This is a holdover from when pipelines were primarily generated via seeds and migrations
# In turn this resulted in integration testing via cucumber, which tested data and configuration
# as much as behaviour.
#
# I've grouped the behaviour here to:
# 1) Remove entirely defunct templates
# 2) Indicate those templates which hang around solely for the sake of the cukes (LEGACY_CUKES_ONLY)
# 3) Retain only those template which correspond to active submission templates
LEGACY_CUKES_ONLY = [
  {
    name: 'Pulldown WGS - HiSeq Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_options: {
        'fragment_size_required_to' => '500',
        'fragment_size_required_from' => '300'
      },
      request_types: %w[pulldown_wgs illumina_a_hiseq_paired_end_sequencing]
    }
  },
  {
    name: 'Library creation - Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceded_at: 'Mon Oct 05 15:58:50 UTC 2015',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[library_creation paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Library creation - Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_library_creation illumina_c_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-A - HTP ISC - Single ended sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_a_shared illumina_a_isc illumina_a_single_ended_sequencing],
      order_role: 'ILA ISC'
    }
  },
  {
    name: 'Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_std illumina_b_hiseq_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-B - Pooled PATH - Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_shared illumina_b_pool illumina_b_paired_end_sequencing],
      order_role: 'ILB PATH'
    }
  },
  {
    name: 'Illumina-B - Pooled PATH - HiSeq Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_shared illumina_b_pool illumina_b_hiseq_paired_end_sequencing],
      order_role: 'ILB PATH'
    }
  },
  {
    name: 'Illumina-C Multiplex - HiSeq Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexing illumina_c_hiseq_paired_end_sequencing],
      order_role: 'PCR'
    }
  }
].freeze

BOTH_DEV_AND_CUKES = [
  {
    name: 'Cherrypick',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 6,
      asset_input_methods: ['select an asset group', 'enter a list of sample names found on plates'],
      request_types: ['cherrypick']
    }
  },
  {
    name: 'Illumina-C - Multiplexed Library Creation - HiSeq 2500 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexed_library_creation illumina_c_hiseq_2500_paired_end_sequencing]
    }
  },
  {
    name: 'PacBio',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      asset_input_methods: ['select an asset group', 'enter a list of sample names'],
      request_types: %w[pacbio_sample_prep pacbio_sequencing]
    }
  }
].freeze

DEV_ONLY = [
  # {
  #   name: 'LCA DNA RNA seq test',
  #   submission_class_name: 'LinearSubmission',
  #   #product_line: 'Illumina-C',
  #   product_catalogue: 'Generic',
  #   submission_parameters: {
  #     request_types: %w[lca_seq_dna_rna]
  #   }
  # },
  {
    name: 'Illumina-C - Cherrypick Internally',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      asset_input_methods: ['select an asset group', 'enter a list of sample names found on plates'],
      request_types: ['illumina_c_cherrypick']
    }
  },
  {
    name: 'Cherrypick for Fluidigm',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 6,
      request_types: %w[pick_to_sta pick_to_sta2 pick_to_snp_type pick_to_fluidigm]
    }
  },
  {
    name: 'Multiplexed PacBio',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[pacbio_tagged_library_prep pacbio_multiplexed_sequencing]
    }
  },
  {
    name: 'MiSeq for TagQC',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: ['qc_miseq_sequencing']
    }
  },
  {
    name: 'Illumina-C - Library creation - HiSeq 2500 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_library_creation illumina_c_hiseq_2500_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Library creation - HiSeq 2500 Single end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_library_creation illumina_c_hiseq_2500_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Library creation - HiSeq V4 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_library_creation illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Library creation - HiSeq V4 Single end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_library_creation illumina_c_hiseq_v4_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Multiplexed Library Creation - HiSeq 2500 Single end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexed_library_creation illumina_c_hiseq_2500_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Multiplexed Library Creation - HiSeq V4 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexed_library_creation illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Multiplexed Library Creation - HiSeq V4 Single end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexed_library_creation illumina_c_hiseq_v4_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-B - Multiplexed Library Creation - HiSeq 2500 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    superceded_at: 'Mon Oct 05 15:58:52 UTC 2015',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_multiplexed_library_creation illumina_b_hiseq_2500_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-B - Multiplexed Library Creation - HiSeq 2500 Single end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    superceded_at: 'Mon Oct 05 15:58:52 UTC 2015',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_multiplexed_library_creation illumina_b_hiseq_2500_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-B - Multiplexed Library Creation - HiSeq V4 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    superceded_at: 'Mon Oct 05 15:58:52 UTC 2015',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_multiplexed_library_creation illumina_b_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-B - Multiplexed Library Creation - HiSeq X Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    superceded_at: 'Mon Oct 05 15:58:52 UTC 2015',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_multiplexed_library_creation illumina_b_hiseq_x_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-A - HiSeq 2500 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    submission_parameters: {
      info_differential: 5,
      request_types: ['illumina_a_hiseq_2500_paired_end_sequencing']
    }
  },
  {
    name: 'Illumina-A - HiSeq 2500 Single end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    submission_parameters: {
      info_differential: 5,
      request_types: ['illumina_a_hiseq_2500_single_end_sequencing']
    }
  },
  {
    name: 'Illumina-A - HiSeq V4 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    submission_parameters: {
      info_differential: 5,
      request_types: ['illumina_a_hiseq_v4_paired_end_sequencing']
    }
  },
  {
    name: 'Illumina-A - HiSeq X Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    superceeded_by_id: -2,
    submission_parameters: {
      info_differential: 5,
      request_types: ['illumina_a_hiseq_x_paired_end_sequencing']
    }
  },
  {
    name: 'Illumina-C - General PCR - HiSeq v4 sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    superceded_by: 'Illumina-C - General PCR - HiSeq v4 sequencing PE',
    superceded_at: 'Mon Oct 05 15:59:05 UTC 2015',
    submission_parameters: {
      request_types: %w[illumina_c_pcr illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - General no PCR - HiSeq v4 sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    superceded_by: 'Illumina-C - General no PCR - HiSeq v4 sequencing PE',
    superceded_at: 'Mon Oct 05 15:59:05 UTC 2015',
    submission_parameters: {
      request_types: %w[illumina_c_nopcr illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Library Creation - HiSeq v4 sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    superceded_by: 'Illumina-C - Library Creation - HiSeq v4 sequencing PE',
    superceded_at: 'Mon Oct 05 15:59:05 UTC 2015',
    submission_parameters: {
      request_types: %w[illumina_c_library_creation illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Multiplexed Library Creation - HiSeq v4 sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    superceded_by: 'Illumina-C - Multiplexed Library Creation - HiSeq v4 sequencing PE',
    superceded_at: 'Mon Oct 05 15:59:05 UTC 2015',
    submission_parameters: {
      request_types: %w[illumina_c_multiplexed_library_creation illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - General PCR - HiSeq v4 sequencing SE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_pcr illumina_c_hiseq_v4_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - General PCR - HiSeq v4 sequencing PE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_pcr illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - General no PCR - HiSeq v4 sequencing SE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_nopcr illumina_c_hiseq_v4_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - General no PCR - HiSeq v4 sequencing PE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_nopcr illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Library Creation - HiSeq v4 sequencing SE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_library_creation illumina_c_hiseq_v4_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Library Creation - HiSeq v4 sequencing PE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_library_creation illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Multiplexed Library Creation - HiSeq v4 sequencing SE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_multiplexed_library_creation illumina_c_hiseq_v4_single_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - Multiplexed Library Creation - HiSeq v4 sequencing PE',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_multiplexed_library_creation illumina_c_hiseq_v4_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - General PCR - HiSeq-X sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_pcr bespoke_hiseq_x_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C - General no PCR - HiSeq-X sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      request_types: %w[illumina_c_nopcr bespoke_hiseq_x_paired_end_sequencing]
    }
  },
  {
    name: 'Illumina-C Multiplex - MiSeq sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexing illumina_c_miseq_sequencing],
      order_role: 'PCR'
    }
  },
  {
    name: 'Illumina-C Multiplex - HiSeq 2500 Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexing illumina_c_hiseq_2500_paired_end_sequencing],
      order_role: 'PCR'
    }
  },
  {
    name: 'Illumina-C Multiplex - HiSeq 2500 Single end sequencing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_c_multiplexing illumina_c_hiseq_2500_single_end_sequencing],
      order_role: 'PCR'
    }
  },
  {
    name: 'Illumina-C - General PCR - No multiplexing',
    submission_class_name: 'LinearSubmission',
    product_line: 'Illumina-C',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 1,
      request_types: ['illumina_c_pcr_no_pool'],
      order_role: 'PCR'
    }
  }
].freeze

LEGACY_CUKES_ONLY.each { |params| SubmissionSerializer.construct!(params) } if Rails.env.cucumber?
BOTH_DEV_AND_CUKES.each { |params| SubmissionSerializer.construct!(params) }
DEV_ONLY.each { |params| SubmissionSerializer.construct!(params) } unless Rails.env.cucumber?
