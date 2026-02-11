# frozen_string_literal: true
#
# This module provides a basic pooling plan generator for scRNA core cDNA prep submissions.
# It generates a CSV string which outlines the pooling strategy for the submitted samples
# based on the number of pools and cells per chip well specified in the submission and grouped by study and project.
# The logic for determining the pool layout is aimed to be a mirror of the pooling logic
# used in Limber, specifically in the DonorPoolingCalculator's allocate_wells_to_pools method.
#
# This module also assumes the submission has already been validated with the scrna_core_cdna_prep validators
# to ensure donor clashes and pooling parameters are already checked.
module Submission::ScrnaCoreCdnaPrepPoolingPlanGenerator
  # This logic attemps to mirror Limber's pooling logic
  # See Limber LabwareCreators::DonorPoolingCalculator (allocate_wells_to_pools)
  def self.generate_pooling_plan(submission)
    CSV.generate(row_sep: "\r\n") do |csv|
      csv << ['Study / Project', 'Pools (num samples)', 'Cells per chip well']
      # It would be nice to refactor the scRNA Validator logic here to pull out the pooling plan logic
      grouped_labware(submission).each do |study_project, subgroup|
        # Get number_of_pools and cells_per_chip_well requested from the submission
        number_of_pools = subgroup.first.request_metadata.number_of_pools
        cells_per_chip_well = subgroup.first.request_metadata.cells_per_chip_well
        # Build the pools
        pools_layout = calculate_pools_layout(subgroup.size, number_of_pools)

        # Join the pool sizes into a string for the CSV output
        number_of_samples_in_pool = pools_layout.join(', ')

        csv << [study_project, number_of_samples_in_pool, cells_per_chip_well]
      end
    end
  end

  # This method calculates the layout of pools based on the total number of samples and the number of pools requested.
  # It divides the samples as evenly as possible across the pools, and evenly distributes any remainder samples
  def self.calculate_pools_layout(number_of_samples, number_of_pools)
    # Ideal pool size is just the number of samples divided by the number of pools, but we need to account for
    # any remainder if the division isn't exact
    ideal_pool_size, remainder = number_of_samples.divmod(number_of_pools)
    pools_layout = Array.new(number_of_pools, ideal_pool_size)
    remainder.times { |i| pools_layout[i] += 1 }
    pools_layout
  end

  # Groups the labware associated with a submission by study and project.
  def self.grouped_labware(submission)
    submission.requests.group_by do |request|
      aliquot = request.asset.aliquots.first
      study = aliquot.study.name
      project = aliquot&.project&.name
      "#{study} / #{project}"
    end
  end
end
