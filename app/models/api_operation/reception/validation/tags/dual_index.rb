# frozen_string_literal: true

# Tags given as a dual index tag set and a well of its plate, which gives the
# tag (i7) and tag 2 (i5). Mirrors the sample manifest's dual_index_tag_set
# and dual_index_tag_well fields (SequencescapeExcel::SpecialisedField::
# DualIndexTagSet and DualIndexTagWell):
# - dual_index_tag_set names a visible dual index tag set, ignoring case:
#   both its tag groups are visible.
# - dual_index_tag_well is a well of the set's plate (A1 to H12, in either
#   case; A01 is read as A1). The well's position by column (A1, B1 ... H1,
#   A2 ... H12) is the index of its i7 tag in the tag group and of its i5
#   tag in the tag 2 group. Both must exist.
# - The receptacle holds only that sample.
# Unlike the manifest, a well that isn't on the plate (I1, A13) is a
# problem, not read as another well.
class ApiOperation::Reception::Validation::Tags::DualIndex <
      ApiOperation::Reception::Validation::Tags::Scheme
  # The payload fields of this scheme
  FIELDS = %w[dual_index_tag_set dual_index_tag_well].freeze

  # How this scheme is named in messages
  NAME = 'dual index tag set and well'

  # The wells of a dual index tag set's plate, as in the sample manifest
  PLATE_SIZE = 96

  # (see ApiOperation::Reception::Validation::Tags::Scheme#errors)
  def errors
    @errors ||=
      begin
        complete, partial_errors =
          split_pair('dual_index_tag_set', 'dual_index_tag_well')
        partial_errors + unknown_tag_set_errors(complete) +
          well_errors(complete) + missing_tag_errors(complete) +
          shared_receptacle_errors('dual index tags')
      end
  end

  private

  def unknown_tag_set_errors(complete)
    complete.group_by { tag_set_name(it) }.filter_map do |name, users|
      next if tag_group_ids(name)

      error("#{users.first.pointer}/dual_index_tag_set",
            "No visible dual index tag set named #{name} " \
            "(#{used_by(users)})")
    end
  end

  def well_errors(complete)
    complete.filter_map do |sample|
      next if plate_well_index(well(sample))

      error("#{sample.pointer}/dual_index_tag_well",
            "#{well(sample)} is not a well of a #{PLATE_SIZE}-well plate")
    end
  end

  # An error for each tag set and well whose i7 or i5 tag is missing, once
  def missing_tag_errors(complete)
    complete.select { known?(it) }.group_by { [tag_set_name(it), well(it)] }
      .flat_map do |(name, well), users|
        missing_tags(tag_group_ids(name), plate_well_index(well))
          .map do |tag|
            error("#{users.first.pointer}/dual_index_tag_well",
                  "Dual index tag set #{name} has no #{tag} tag for well " \
                  "#{well} (#{used_by(users)})")
          end
      end
  end

  # @return [Array<String>] which of the i7 and i5 tags are missing
  def missing_tags(group_ids, index)
    %w[i7 i5].zip(group_ids).filter_map do |tag, group_id|
      tag unless tags.include?([group_id, index])
    end
  end

  # Whether the sample names an existing tag set and a well of its plate
  def known?(sample)
    tag_group_ids(tag_set_name(sample)) && plate_well_index(well(sample))
  end

  def tag_set_name(sample)
    sample.fields['dual_index_tag_set']
  end

  def well(sample)
    sample.fields['dual_index_tag_well']
  end

  # The well's position by column on the set's plate. The manifest reads the
  # well in upper case.
  def plate_well_index(well)
    well_index(well.upcase, PLATE_SIZE)
  end

  # @return [Array(Integer, Integer), nil] the IDs of the tag set's tag
  #   group and tag 2 group
  def tag_group_ids(name)
    tag_sets[name.downcase]
  end

  # The tag group and tag 2 group IDs of the tag sets the samples name, by
  # lower-case name
  def tag_sets
    @tag_sets ||=
      begin
        names = samples.filter_map { tag_set_name(it) }.uniq
        TagSet.dual_index.visible.where(name: names)
          .pluck('tag_sets.name', 'tag_sets.tag_group_id',
                 'tag_sets.tag2_group_id')
          .to_h { |name, *group_ids| [name.downcase, group_ids] }
      end
  end

  # The tag group ID and index of each tag in the named tag sets' groups
  def tags
    @tags ||=
      Tag.where(tag_group_id: tag_sets.values.flatten)
        .where.not(map_id: nil).pluck(:tag_group_id, :map_id).to_set
  end
end
