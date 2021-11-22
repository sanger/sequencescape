# frozen_string_literal: true

# Handles the generation of user-friendly summaries of tag-clashes on the custom
# poolings page (PoolingsController#new) in accordance with story gpl021
# Wraps the Pooling object itself
class Pooling::TagClashReport < SimpleDelegator
  include SampleManifestExcel::Tags::ClashesFinder

  # An oligo pair which clashes and details about the clashes causing the problem
  Clash = Struct.new(:i7_oligo, :i5_oligo, :clashes)
  ClashInfo = Struct.new(:sample, :library, :asset)
  UNTAGGED = '-'

  def tag_clash?
    duplicates.present?
  end

  def duplicates
    @duplicates ||= grouped_aliquots.select { |_unique_key, aliquot_group| aliquot_group.length > 1 }
  end

  def clashes
    duplicates.map do |oligos, clashes|
      Clash.new(
        oligos.first || UNTAGGED,
        oligos.last || UNTAGGED,
        clashes.map { |clashed_aliquot| clash_info(clashed_aliquot) }
      )
    end
  end

  private

  def grouped_aliquots
    aliquots.group_by(&:tags_combination)
  end

  def aliquots
    source_assets.flat_map(&:aliquots)
  end

  def clash_info(aliquot)
    ClashInfo.new(aliquot.sample, aliquot.library, aliquot.receptacle)
  end
end
