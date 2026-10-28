# frozen_string_literal: true

# Checks the tags of the samples in the new labware. A sample gives its tags
# in one of several ways (schemes, in SCHEMES), each by its own fields, or
# gives none. A sample that gives fields of more than one scheme is a
# problem, and its tags aren't checked further. Each scheme then checks the
# samples that give their tags its way.
#
# Then, in each new receptacle, the aliquots with tags must have different
# tags, as the multiplexed library tube manifest checks: the oligos of their
# i7 and i5 tags are compared, ignoring case, not the tag records, as
# different tags can have the same oligos. Untagged samples sharing a
# receptacle are a pool, told apart by tag depth, so they aren't compared.
# A receptacle with a tag problem is not compared, as its tags are unknown.
class ApiOperation::Reception::Validation::TagCheck <
      ApiOperation::Reception::Validation::Check
  # The ways a sample can give its tags
  SCHEMES = [
    ApiOperation::Reception::Tags::Oligos,
    ApiOperation::Reception::Tags::TagGroups,
    ApiOperation::Reception::Tags::Chromium,
    ApiOperation::Reception::Tags::DualIndex
  ].freeze

  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    @errors ||=
      begin
        tag_errors =
          mixed_scheme_errors + schemes.values.flat_map(&:errors)
        tag_errors + clash_errors(tag_errors)
      end
  end

  private

  # Each scheme, given the samples that give their tags its way
  def schemes
    @schemes ||=
      SCHEMES.index_with { |scheme| scheme.new(samples_using(scheme), input) }
  end

  # An error for each sample that gives fields of more than one scheme
  def mixed_scheme_errors
    input.new_samples.filter_map do |sample|
      schemes = schemes_of(sample)
      next unless schemes.many?

      error(sample.pointer,
            "Sample #{sample.sanger_sample_id} gives its tags in more than " \
            "one way: #{schemes.map { it::NAME }.to_sentence}")
    end
  end

  # An error for each clash, in the new receptacles without tag problems
  def clash_errors(tag_errors)
    pointers = tag_errors.pluck(:pointer)
    input.new_labware.flat_map(&:receptacles).flat_map do |receptacle|
      next [] if pointers.any? { within?(it, receptacle.pointer) }

      receptacle_clash_errors(receptacle)
    end
  end

  # An error for each pair of oligos given for more than one aliquot
  def receptacle_clash_errors(receptacle)
    tagged_aliquots(receptacle).group_by(&:first)
      .filter_map do |pair, aliquots|
        next unless aliquots.many?

        error(receptacle.pointer,
              clash_detail(pair, aliquots.map(&:last).uniq))
      end
  end

  # The receptacle's aliquots with tags: their oligo pair, in upper case,
  # and the pointer to the sample they're of
  def tagged_aliquots(receptacle)
    receptacle.samples.flat_map do |sample|
      oligos_of(sample).filter_map do |pair|
        [pair.map { it&.upcase }, sample.pointer] if pair.any?
      end
    end
  end

  # The oligo pairs of the sample's aliquots; none for an untagged sample
  def oligos_of(sample)
    scheme = schemes_of(sample).first
    scheme ? schemes.fetch(scheme).oligos(sample) : []
  end

  def clash_detail(pair, sample_pointers)
    tags = describe_tags(pair)
    if sample_pointers.one?
      "The same tags (#{tags}) are given more than once for " \
        "#{sample_pointers.first}"
    else
      "The same tags (#{tags}) are given for #{sample_pointers.to_sentence}"
    end
  end

  # The pair's oligos, named by tag: "i7 ACGT, i5 TTGA"
  def describe_tags(pair)
    %w[i7 i5].zip(pair).filter_map { |tag, oligo| "#{tag} #{oligo}" if oligo }
      .join(', ')
  end

  # Whether the pointer is the base pointer, or a pointer inside it
  def within?(pointer, base)
    pointer == base || pointer.start_with?("#{base}/")
  end

  # The samples that give their tags the scheme's way, and no other
  def samples_using(scheme)
    input.new_samples.select { |sample| schemes_of(sample) == [scheme] }
  end

  # @return [Array<Class>] the schemes whose fields the sample gives
  def schemes_of(sample)
    SCHEMES.select { |scheme| sample.fields.keys.intersect?(scheme::FIELDS) }
  end
end
