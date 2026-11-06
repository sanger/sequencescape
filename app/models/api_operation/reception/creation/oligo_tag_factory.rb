# frozen_string_literal: true

# Finds or creates the tags of i7 and i5 oligos in the tag group sample
# manifests use for them (the Magic Tag Group, named by
# SampleManifestExcel.configuration.tag_group), as manifests do
# (SampleManifest::Uploader#create_tag_group,
# SampleManifestExcel::Tags::AliquotUpdater). An oligo's tag is the group's
# tag with that oligo, found ignoring case, or a new one, numbered on from the
# group's tags. New tags keep the oligo as given.
class ApiOperation::Reception::Creation::OligoTagFactory
  # @param oligos [Array<String>] the oligos the samples give
  def initialize(oligos)
    @oligos = oligos
  end

  # @param oligo [String] one of the oligos
  # @return [Integer] the ID of its tag
  def tag_id(oligo)
    tag_ids[oligo.downcase] ||= create_tag(oligo).id
  end

  private

  def create_tag(oligo)
    tag_group.tags.create!(oligo: oligo, map_id: tag_group.tags.count + 1)
  end

  # The IDs of the group's tags with the oligos, by oligo in lower case,
  # looked up once
  def tag_ids
    @tag_ids ||=
      tag_group.tags.where(oligo: @oligos).pluck(:oligo, :id)
        .to_h { |oligo, id| [oligo.downcase, id] }
  end

  def tag_group
    @tag_group ||= TagGroup.find_or_create_by!(
      name: SampleManifestExcel.configuration.tag_group
    )
  end
end
