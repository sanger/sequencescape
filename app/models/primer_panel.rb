#
# A primer panel is a set of primers used in a genotyping by sequencing assay.
# These primers bind to known regions of DNA, localised near SNPs (Single Nucleotide polymorphisms)
# to allow them to be targeted by short read Sequencing.
#
# @author Genome Research Ltd.
#
class PrimerPanel < ApplicationRecord
  include ActiveModel::Validations

  serialize :programs
  # The name: Used to identify the assay set.
  validates :name, presence: true
  # The number of SNP sites targeted by the panel. Primarily used for reference, and to ensure
  # that SNP calls can be presented along with the expected number of hits.
  validates :snp_count, numericality: { greater_than: 0, only_integer: true }
  validates :programs, programs: true
end
