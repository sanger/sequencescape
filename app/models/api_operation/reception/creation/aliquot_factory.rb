# frozen_string_literal: true

# Puts the new samples into their receptacles as aliquots, as sample manifests
# do. Each aliquot has its sample, the sample's study and the library fields
# (library type, insert sizes, primer panel). On library labware, whose
# samples have tags, an aliquot's library is its receptacle, as library
# manifests set it.
#
# A sample with tags gets an aliquot for each tag pair its scheme gives
# (Tags::Scheme#tag_ids), with those tags: one for a tag group and index, or
# a dual index well, and one for each tag of a Chromium well, as
# Tag#multitag! gives. A sample giving i7/i5 oligos gets one aliquot, with
# their tags from the Magic Tag Group (OligoTagFactory). Samples without tags
# that share a receptacle (a pool) get their positions among the
# receptacle's samples as tag depths (0, 1, 2 ...), as stock manifests give
# them, so their aliquots can be told apart.
class ApiOperation::Reception::Creation::AliquotFactory
  # The payload fields of the tag schemes; a sample with any of them has tags
  TAG_FIELDS = ApiOperation::Reception::Validation::SampleCheck::TAG_FIELDS

  # The fields of tags given as oligos: i7 for the tag, i5 for tag 2
  OLIGO_FIELDS = ApiOperation::Reception::Tags::Oligos::FIELDS

  # The ways of giving tags from existing tag groups
  SCHEMES = [
    ApiOperation::Reception::Tags::TagGroups,
    ApiOperation::Reception::Tags::DualIndex,
    ApiOperation::Reception::Tags::Chromium
  ].freeze

  # @param labware [Hash{ApiOperation::Reception::Payload::PayloadLabware =>
  #   Labware}] the new labware, by its payload labware
  # @param samples [Hash{String => Sample}] the new samples, by UUID
  def initialize(labware, samples)
    @labware = labware
    @samples = samples
  end

  # Creates the aliquots.
  #
  # @return [void]
  def call
    @labware.each do |payload_labware, labware|
      library_labware = library?(payload_labware)
      payload_labware.receptacles.each do |payload_receptacle|
        create_aliquots(payload_receptacle,
                        receptacle(labware, payload_receptacle),
                        library_labware)
      end
    end
  end

  private

  # Labware is library labware when its samples have tags
  def library?(payload_labware)
    payload_labware.receptacles.flat_map(&:samples).any? { tagged?(it) }
  end

  def create_aliquots(payload_receptacle, receptacle, library_labware)
    pool = payload_receptacle.samples.many?
    payload_receptacle.samples.each_with_index do |payload_sample, position|
      tag_depth = position if pool && !tagged?(payload_sample)
      tag_id_pairs(payload_sample).each do |tag_id, tag2_id|
        receptacle.aliquots.create!(
          aliquot_attributes(payload_sample).merge(
            tag_id: tag_id, tag2_id: tag2_id, tag_depth: tag_depth,
            # A library is identified by a receptacle: on library labware,
            # each aliquot's library is the receptacle it is in
            library: (receptacle if library_labware)
          ).compact
        )
      end
    end
  end

  # The [tag_id, tag2_id] pair of each of the sample's aliquots: one aliquot
  # without tags for a sample without tags
  def tag_id_pairs(payload_sample)
    fields = payload_sample.fields
    return [[nil, nil]] unless tagged?(payload_sample)
    return oligo_tag_id_pairs(fields) if fields.keys.intersect?(OLIGO_FIELDS)

    scheme = SCHEMES.find { fields.keys.intersect?(it::FIELDS) }
    schemes.fetch(scheme).tag_ids(payload_sample)
  end

  # The tags of the i7 and i5 oligos, for the sample's one aliquot
  def oligo_tag_id_pairs(fields)
    [fields.values_at(*OLIGO_FIELDS).map { it && oligo_tag_id(it) }]
  end

  def oligo_tag_id(oligo)
    @oligo_tags ||= ApiOperation::Reception::Creation::OligoTagFactory
      .new(field_values(*OLIGO_FIELDS))
    @oligo_tags.tag_id(oligo)
  end

  # Each scheme, given the new samples that give their tags its way
  def schemes
    @schemes ||= begin
      new_labware = @labware.keys
      input = ApiOperation::Reception::Validation::Input.build(new_labware,
                                                               new_labware)
      SCHEMES.index_with do |scheme|
        scheme.new(input.new_samples.select do |payload_sample|
          payload_sample.fields.keys.intersect?(scheme::FIELDS)
        end, input)
      end
    end
  end

  def aliquot_attributes(payload_sample)
    sample = @samples.fetch(payload_sample.uuid)
    fields = payload_sample.fields
    {
      sample: sample,
      study: sample.studies.first,
      library_type: library_type_name(fields),
      insert_size_from: fields['insert_size_from'],
      insert_size_to: fields['insert_size_to'],
      primer_panel: primer_panels[fields['primer_panel']&.downcase]
    }.compact
  end

  # The well at the payload's position, or the tube's receptacle
  def receptacle(labware, payload_receptacle)
    return labware.receptacle if payload_receptacle.position.nil?

    @wells ||= {}
    @wells[labware] ||= labware.wells.includes(:map).index_by(&:map_description)
    @wells[labware].fetch(payload_receptacle.position)
  end

  def tagged?(payload_sample)
    payload_sample.fields.keys.intersect?(TAG_FIELDS)
  end

  # The library type's own name: the payload may give it in another case.
  # library_type_long_read sets the same field.
  def library_type_name(fields)
    name = fields['library_type'] || fields['library_type_long_read']
    library_types[name&.downcase]&.name
  end

  # The library types the samples name, by name in lower case, looked up once
  def library_types
    @library_types ||=
      LibraryType.where(name: field_values('library_type',
                                           'library_type_long_read'))
        .index_by { it.name.downcase }
  end

  # The primer panels the samples name, by name in lower case, looked up once
  def primer_panels
    @primer_panels ||=
      PrimerPanel.where(name: field_values('primer_panel'))
        .index_by { it.name.downcase }
  end

  # The values the new samples give for the fields
  def field_values(*names)
    @labware.keys.flat_map(&:receptacles).flat_map(&:samples)
      .flat_map { it.fields.values_at(*names) }.compact.uniq
  end
end
