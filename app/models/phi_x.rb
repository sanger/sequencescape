# frozen_string_literal: true

# == PhiX
# PhiX is a well characterized bacteriophage with a small, known, genome.
# It is used to provide short DNA sequences which can get added to sequencing
# {Lane lanes} for control and calibration purposes.
#
# == Process
# PhiX samples arrive on site and have {Tag tags} applied as required. These may be
# single indexed (i7 only) or dual indexed (i5 & i7) as required. The single and
# dual indexed tag sets are fixed and are selected from the 'Control Tag Group 888'
# {TagGroup}.
#
# Library information is filled in on the {PhiXesController#show} page and one or
# more {LibraryTube library tubes} are generated via {PhiX::StocksController#create}
# and the {PhiX::Stock} factory. These tubes are considered stocks, and get
# transferred to the sequencing teams.
#
# Subsequently the sequencing team will split the contents of each {LibraryTube}
# into a number of {SpikedBuffer} tubes, adjusting the volume and concentration
# as required. This is achieved via a separate form on the {PhiXesController#show}
# page, followed by {PhiX::SpikedBuffersController#create} and the {PhiX::SpikedBuffer}
# factory.
#
# Finally, during the processing of a {SequencingPipeline} the {SpikedBuffer}
# barcode is scanned in during the {AddSpikedInControlTask}. This adds the
# {SpikedBuffer} in as a parent of each {Lane} in the {Batch}, which in turn
# ensures the control can be found by {BatchesController#show batch.xml generation}
# and {Api::Messages::FlowcellIO}.
#
# == Configuration
# Configuration and values are stored in config/phi_x.yml
# tag_group_name: The name of the tag group to use
# tag_map_id: The default map_id for tags
# tag_options: Hash of available tag options, indexed by option name.
#              Values are hashes of i5 and i7 oligos. null indicates no tag.
# default_tag_option: The option which will be initially selected
#
module PhiX
  #
  # Returns the configuration as defined in {file:'config/phi_x.yml'}
  #
  # @return [Hash] Configuration. See above.
  def self.configuration
    Rails.application.config.phi_x
  end

  # Returns the tag_options configured.
  # @return [Hash] Hash of available tag options, indexed by option name.
  #                Values are hashes of i5 and i7 oligos. null indicates no tag.
  def self.tag_options
    configuration[:tag_options]
  end

  # Returns the names of valid tag options for creation of PhiX libraries.
  # @return [Array] Valid tag options
  def self.tag_option_names
    tag_options.keys.map(&:to_s)
  end

  # Returns the default tag option which will be automatically selected when
  # generating new PhiX stocks
  # @return [String] The default tag option
  def self.default_tag_option
    configuration[:default_tag_option]
  end

  # Returns the purpose used to generate new PhiX Stocks
  # creates it if it doesn't exist
  # @return [Tube::Purpose] The tube purpose
  def self.stock_purpose
    Tube::Purpose.create_with(target_type: 'LibraryTube').find_or_create_by(name: 'PhiX Stock')
  end

  # Returns the purpose used to generate new PhiX SpikedBuffers
  # creates it if it doesn't exist
  # @return [Tube::Purpose] The tube purpose
  def self.spiked_buffer_purpose
    Tube::Purpose.create_with(target_type: 'SpikedBuffer').find_or_create_by(name: 'PhiX Spiked Buffer')
  end

  # Returns the sample the represents PhiX, creates it if it doesn't exist
  # @return [Sample] PhiX Sample
  def self.sample
    Sample.find_or_create_by!(name: 'phiX_for_spiked_buffers')
  end

  # Returns the tag group for PhiX tags or creates it if it doesn't exist
  # @return [TagGroup] The TagGroup for PhiX tags
  def self.tag_group
    TagGroup.find_or_create_by!(name: configuration[:tag_group_name])
  end

  # Returns the {Study studies} that can be used to register PhiX
  # @return [Study::ActiveRecord_Relation]
  def self.studies
    Study.where(name: configuration[:studies])
  end

  def self.default_study_option
    Study.find_by(name: configuration[:default_study_option])
  end

  #
  # Performs a lookup of the tag option matching the given oligo pair.
  # If no option can be found returns:
  # UNKOWN i7:i7_olgo i5:i5_oligo
  # @param i7_oligo [String] The i7 (tag) oligo sequence
  # @param i5_oligo [String] The i5 (tag2) oligo sequence
  #
  # @return [String] The named tag option.
  def self.tag_option_for(i7_oligo:, i5_oligo:)
    tag_options.deep_symbolize_keys.key(i7_oligo:, i5_oligo:)&.to_s ||
      "UNKNOWN i7:#{i7_oligo || '-'} i5:#{i5_oligo || '-'}"
  end

  #
  # Returns the appropriate tag or creates it if it doesn't exist.
  # @param tag_option [String] The selected tag_option from which the tags will be selected. eg. 'Single'
  # @param tag_type [:i7_oligo, :i5_oligo] The tag which will be applied
  #
  # @return [Tag, nil] The tag to apply, or nil if it is to be untagged
  def self.find_tag(tag_option, tag_type)
    oligo = tag_options.dig(tag_option.to_sym, tag_type)
    return nil if oligo.nil?

    tag_group.tags.create_with(map_id: configuration[:tag_map_id]).find_or_create_by!(oligo:)
  end
end
