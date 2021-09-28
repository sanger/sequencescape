# frozen_string_literal: true

# PhiX is a short DNA fragment of known sequence which gets added into {Lane lanes}
# of sequencing to provide a control. PhiX arrives on site in bulk where it is tagged
# with a fixed i7 {Tag tag}, or fixed i5 and i7 tags.
# - When this occurs one or
#   more {LibraryTube library tubes} are created in Sequencescape each containing
#   an aliquot of the PhiX {Sample} (See {PhiX#sample}) with the appropriate
#   tags applied.
# - At a later date, the {LibraryTube} {Barcode} is scanned in to Sequencescape
#   and is used to create one or more tubes of {SpikedBuffer}.
# - Finally these tubes get used in the {AddSpikedInControlTask} during the {SequencingPipeline}
#
# This controller handles the rendering of the two forms for creating the {LibraryTube} and
# the {SpikedBuffer}. Actual creation is handled by the respective controllers.
# {PhiX::Stock} and {PhiX::SpikedBuffer} act as factories
class PhiXesController < ApplicationController
  def show
    @stock = PhiX::Stock.new(number: 1, tags: PhiX.default_tag_option, study_id: PhiX.default_study_option&.id)
    @spiked_buffer = PhiX::SpikedBuffer.new(number: 1)
    @tag_option_names = PhiX.tag_option_names.map(&:to_s)
    @study_names = PhiX.studies.for_select_association
  end
end
