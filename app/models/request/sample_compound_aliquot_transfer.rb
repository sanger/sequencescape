# frozen_string_literal: true

# Module to provide support to handle creation of compound samples
# from the list of samples at the source. A compound sample is a
# sample that represents a combination of other samples.
#
# The reason for this is to ensure that when the data gets to the MLWH,
# each row has a unique combination of tag1 and tag2 -
# this is a requirement for the Illumina de-plexing that NPG does.
#
# tag_depth on aliquot is used to indicate that,
# even though certain aliquots might share the same tags, they can in fact
# be separated out by other means
# (e.g. by genotype, because they have been sequenced before).
#
# In the case where multiple aliquots share the same tag1 tag2 combo,
# we represent them as a single aliquot with a single sample
# in the target Lane, but link the sample back to its component sample
# using the SampleCompoundComponent join object.
#
# Assumptions:
#  - This module will be included in a Request class
module Request::SampleCompoundAliquotTransfer
  DUPLICATE_TAG_DEPTH_ERROR_MSG = "Cannot create compound sample from following samples due to duplicate 'tag depth'"
  MULTIPLE_STUDIES_ERROR_MSG =
    'Cannot create compound sample due to the component samples being under different studies.'

  # Indicates if a compound sample creation is needed, by checking
  # if any of the source aliquots share the same tag1 and tag2
  def compound_samples_needed?
    return false if asset.aliquots.count == 1

    _any_aliquots_share_tag_combination?
  end

  # Groups the source aliquots by their tag1 and tag2 combination
  # For each of these groups, create a compound sample.
  def transfer_aliquots_into_compound_sample_aliquots
    _aliquots_by_tags_combination.each do |_tags_combo, aliquot_list|
      _transfer_into_compound_sample_aliquot(aliquot_list)
    end
  end

  private

  def _any_aliquots_share_tag_combination?
    _aliquots_by_tags_combination.any? { |_tags_combo, aliquot_list| aliquot_list.size > 1 }
  end

  def _aliquots_by_tags_combination
    asset.aliquots.group_by(&:tags_combination)
  end

  def _transfer_into_compound_sample_aliquot(source_aliquots)
    compound_aliquot = CompoundAliquot.new(request: self, source_aliquots: source_aliquots)

    raise compound_aliquot.errors unless compound_aliquot.valid?

    compound_aliquot.create_compound_sample

    target_asset.aliquots.create(compound_aliquot.aliquot_attributes)
  end
end
