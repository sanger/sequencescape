# frozen_string_literal: true

# Tags given as a tag group and the tag's index in it, for the tag (tag_group,
# tag_index) and for tag 2 (tag2_group, tag2_index). Mirrors the sample
# manifest's tag_group, tag_index, tag2_group and tag2_index fields: the group
# is found by name, ignoring case, and the tag by its index (map_id) in it.
# A group needs its index and an index its group. An unknown group, or a
# missing tag, is reported once, at the first sample that names it, with how
# many do. All the groups and their tags are looked up in two queries.
class ApiOperation::Reception::Validation::Tags::TagGroups <
      ApiOperation::Reception::Validation::Tags::Scheme
  # The payload fields of this scheme
  FIELDS = %w[tag_group tag_index tag2_group tag2_index].freeze

  # How this scheme is named in messages
  NAME = 'tag group and index'

  # Each group field with its index field: for the tag, and for tag 2
  PAIRS = { 'tag_group' => 'tag_index', 'tag2_group' => 'tag2_index' }.freeze

  # (see ApiOperation::Reception::Validation::Tags::Scheme#errors)
  def errors
    @errors ||=
      PAIRS.flat_map do |group_field, index_field|
        pair_errors(group_field, index_field)
      end
  end

  # (see ApiOperation::Reception::Validation::Tags::Scheme#oligos)
  def oligos(sample)
    [PAIRS.map do |group_field, index_field|
      name = sample.fields[group_field]
      tags[[tag_group_id(name), sample.fields[index_field]]] if name
    end]
  end

  private

  def pair_errors(group_field, index_field)
    complete, partial_errors = split_pair(group_field, index_field)
    partial_errors + unknown_group_errors(complete, group_field) +
      missing_tag_errors(complete, group_field, index_field)
  end

  def unknown_group_errors(complete, group_field)
    complete.group_by { it.fields[group_field] }.filter_map do |name, samples|
      next if tag_group_id(name)

      error("#{samples.first.pointer}/#{group_field}",
            "No tag group named #{name} (#{used_by(samples)})")
    end
  end

  def missing_tag_errors(complete, group_field, index_field)
    complete.select { tag_group_id(it.fields[group_field]) }
      .group_by { [it.fields[group_field], it.fields[index_field]] }
      .filter_map do |(name, index), samples|
        next if tag?(tag_group_id(name), index)

        error("#{samples.first.pointer}/#{index_field}",
              "Tag group #{name} has no tag with index #{index} " \
              "(#{used_by(samples)})")
      end
  end

  # @return [Integer, nil] the ID of the tag group with the name
  def tag_group_id(name)
    tag_group_ids[name.downcase]
  end

  # The IDs of the tag groups the samples name, by lower-case name
  def tag_group_ids
    @tag_group_ids ||=
      begin
        names = samples.flat_map { it.fields.values_at(*PAIRS.keys) }
        TagGroup.where(name: names.compact.uniq).pluck(:name, :id)
          .to_h { |name, id| [name.downcase, id] }
      end
  end

  def tag?(tag_group_id, index)
    tags.key?([tag_group_id, index])
  end

  # The oligo of each tag in the groups the samples name, by group ID and
  # index
  def tags
    @tags ||= oligos_by_tag(tag_group_ids.values)
  end
end
