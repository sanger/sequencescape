# frozen_string_literal: true

# Tags given as a 10x Chromium single-index tag set and a well of its kit
# plate. Mirrors the sample manifest's chromium_tag_group and
# chromium_tag_well fields (SequencescapeExcel::SpecialisedField::
# ChromiumTagGroup and ChromiumTagWell):
# - chromium_tag_group names a visible single-index Chromium tag set,
#   ignoring case; its tag group holds the tags.
# - chromium_tag_well is a well of the kit's plate (A1 to H12; A01 is read
#   as A1). Each well has TAGS_PER_WELL tags. The well's position by column
#   (A1, B1 ... H1, A2 ... H12) gives their indexes in the group: A1 has
#   1 to 4, B1 5 to 8, and so on. All of them must exist.
# - The receptacle holds only that sample, which gets an aliquot for each
#   of the well's tags.
# Unlike the manifest, a well that isn't on the kit plate (I1, a1, A13) is a
# problem, not read as another well.
class ApiOperation::Reception::Tags::Chromium <
      ApiOperation::Reception::Tags::Scheme
  # The payload fields of this scheme
  FIELDS = %w[chromium_tag_group chromium_tag_well].freeze

  # How this scheme is named in messages
  NAME = 'Chromium tag group and well'

  # The tags in each well of a Chromium kit plate, as in the sample manifest
  TAGS_PER_WELL = 4

  # The wells of a Chromium kit plate, as in the sample manifest
  KIT_PLATE_SIZE = 96

  # (see ApiOperation::Reception::Tags::Scheme#errors)
  def errors
    @errors ||=
      begin
        complete, partial_errors =
          split_pair('chromium_tag_group', 'chromium_tag_well')
        partial_errors + unknown_tag_set_errors(complete) +
          well_errors(complete) + missing_tag_errors(complete) +
          shared_receptacle_errors('Chromium tags')
      end
  end

  # The indexes (map_ids) in the tag group of the tags of a well, by its
  # position by column (1 for A1)
  #
  # @param well_index [Integer] the well's position by column, from 1
  # @return [Array<Integer>] the tag indexes
  def self.map_ids(well_index)
    Array.new(TAGS_PER_WELL) { ((well_index - 1) * TAGS_PER_WELL) + it + 1 }
  end

  # (see ApiOperation::Reception::Tags::Scheme#oligos)
  def oligos(sample)
    pairs(sample, tags)
  end

  # (see ApiOperation::Reception::Tags::Scheme#tag_ids)
  def tag_ids(sample)
    pairs(sample, tag_ids_by_index)
  end

  private

  # The well's tags, as found by group ID and index in by_index: a pair for
  # each of the sample's TAGS_PER_WELL aliquots, without a tag 2
  def pairs(sample, by_index)
    group_id = tag_group_id(tag_set_name(sample))
    self.class.map_ids(kit_well_index(well(sample)))
      .map { [by_index[[group_id, it]], nil] }
  end

  def unknown_tag_set_errors(complete)
    complete.group_by { tag_set_name(it) }.filter_map do |name, samples|
      next if tag_group_id(name)

      error("#{samples.first.pointer}/chromium_tag_group",
            'No visible single-index Chromium tag set named ' \
            "#{name} (#{used_by(samples)})")
    end
  end

  def well_errors(complete)
    complete.filter_map do |sample|
      well = sample.fields['chromium_tag_well']
      next if kit_well_index(well)

      error("#{sample.pointer}/chromium_tag_well",
            "#{well} is not a well of a #{KIT_PLATE_SIZE}-well kit plate")
    end
  end

  # An error for each tag set and well without all the well's tags, once
  def missing_tag_errors(complete)
    complete.select { known?(it) }.group_by { [tag_set_name(it), well(it)] }
      .filter_map do |(name, well), samples|
        next if all_tags?(tag_group_id(name), kit_well_index(well))

        error("#{samples.first.pointer}/chromium_tag_well",
              "Chromium tag set #{name} doesn't have the #{TAGS_PER_WELL} " \
              "tags of well #{well} (#{used_by(samples)})")
      end
  end

  # Whether the sample names an existing tag set and a well of the kit plate
  def known?(sample)
    tag_group_id(tag_set_name(sample)) && kit_well_index(well(sample))
  end

  def tag_set_name(sample)
    sample.fields['chromium_tag_group']
  end

  def well(sample)
    sample.fields['chromium_tag_well']
  end

  # @return [Integer, nil] the ID of the tag group of the tag set
  def tag_group_id(name)
    tag_group_ids[name.downcase]
  end

  # The tag group IDs of the tag sets the samples name, by lower-case name
  def tag_group_ids
    @tag_group_ids ||=
      begin
        names = samples.filter_map { tag_set_name(it) }.uniq
        TagSet.visible_single_index_chromium.where(name: names)
          .pluck('tag_sets.name', 'tag_sets.tag_group_id')
          .to_h { |name, id| [name.downcase, id] }
      end
  end

  def kit_well_index(well)
    well_index(well, KIT_PLATE_SIZE)
  end

  def all_tags?(tag_group_id, well_index)
    self.class.map_ids(well_index).all? { tags.key?([tag_group_id, it]) }
  end

  # The oligo of each tag in the named tag sets' groups, by group ID and
  # index
  def tags
    @tags ||= oligos_by_tag(tag_group_ids.values)
  end

  # The ID of each tag in the named tag sets' groups, by group ID and index
  def tag_ids_by_index
    @tag_ids_by_index ||= ids_by_tag(tag_group_ids.values)
  end
end
