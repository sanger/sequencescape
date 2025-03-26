# frozen_string_literal: true

#
# A primer panel is a set of primers used in a genotyping by sequencing assay.
# These primers bind to known regions of DNA, localised near SNPs (Single Nucleotide polymorphisms)
# to allow them to be targeted by short read Sequencing.
#
# @author Genome Research Ltd.
#
class PrimerPanel < ApplicationRecord
  include ActiveModel::Validations
  include SharedBehaviour::Named

  serialize :programs, coder: YAML

  # The name: Used to identify the assay set.
  validates :name, presence: true

  # The number of SNP sites targeted by the panel. Primarily used for reference, and to ensure
  # that SNP calls can be presented along with the expected number of hits.
  validates :snp_count, numericality: { greater_than: 0, only_integer: true }
  validates :programs, programs: true, presence: true

  #
  # A summary of the primer panel behaviour, suitable for embedding in
  # eg. pool information via the API
  #
  # @return [Hash] A hash containing all necessary information
  #
  def summary_hash
    attributes.slice('name', 'snp_count', 'programs')
  end
end
