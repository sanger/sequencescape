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

  private

  def pair_errors(group_field, index_field)
    pair = [group_field, index_field]
    giving = samples.select { pair.intersect?(it.fields.keys) }
    complete, partial = giving.partition { (pair - it.fields.keys).empty? }
    partial_errors(partial, group_field, index_field) +
      unknown_group_errors(complete, group_field) +
      missing_tag_errors(complete, group_field, index_field)
  end

  # An error for each sample with a group but no index, or the other way
  def partial_errors(partial, group_field, index_field)
    partial.map do |sample|
      given, missing =
        if sample.fields.key?(group_field)
          [group_field, index_field]
        else
          [index_field, group_field]
        end
      error("#{sample.pointer}/#{given}", "#{given} needs a #{missing}")
    end
  end

  def unknown_group_errors(complete, group_field)
    complete.group_by { it.fields[group_field] }.filter_map do |name, users|
      next if tag_group_id(name)

      error("#{users.first.pointer}/#{group_field}",
            "No tag group named #{name} (#{used_by(users)})")
    end
  end

  def missing_tag_errors(complete, group_field, index_field)
    complete.select { tag_group_id(it.fields[group_field]) }
      .group_by { [it.fields[group_field], it.fields[index_field]] }
      .filter_map do |(name, index), users|
        next if tag?(tag_group_id(name), index)

        error("#{users.first.pointer}/#{index_field}",
              "Tag group #{name} has no tag with index #{index} " \
              "(#{used_by(users)})")
      end
  end

  def used_by(users)
    "used by #{users.size} #{'sample'.pluralize(users.size)}"
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
    tags.include?([tag_group_id, index])
  end

  # The tag group ID and index of each tag in the groups the samples name
  def tags
    @tags ||=
      Tag.where(tag_group_id: tag_group_ids.values).where.not(map_id: nil)
        .pluck(:tag_group_id, :map_id).to_set
  end
end
