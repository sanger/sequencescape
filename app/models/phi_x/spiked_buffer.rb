# frozen_string_literal: true

# {include:PhiXesController}
#
# PhiX::SpikedBuffer acts as a factory to generate the required {SpikedBuffer spiked buffer}
class PhiX::SpikedBuffer
  include ActiveModel::Model

  # @return [String] the base name for the created {LibraryTube library tubes}
  #                  Will be appended with #n to distinguish multiple tubes.
  #                  eg. ('Tube name #1', 'Tube name #2')
  attr_accessor :name

  # @return [String] The barcode of the LibraryTube from which the SpikedBuffer
  # has been created
  attr_accessor :parent_barcode

  # @return [Float] The concentration of the created library in nM
  attr_accessor :concentration

  # @return [Float] The volume of the created library in ul
  attr_accessor :volume

  # @return [Integer] The number of {SpikedBuffer library tubes} to create
  attr_accessor :number

  # @return [Tube] PhiX containing parent tube. If not provided will look up via the parent_barcode
  attr_writer :parent

  # @return [Integer] The id of the {Study} to associate with the {Aliquot}
  attr_accessor :study_id

  validates :name, presence: true
  validates :concentration, numericality: { greater_than: 0, only_integer: false }
  validates :volume, numericality: { greater_than: 0, only_integer: false }
  validates :number, numericality: { greater_than: 0, only_integer: true }
  validates :parent, presence: { message: 'could not be found with that barcode' }, if: :parent_barcode
  validate :parent_contains_phi_x, if: :parent

  #
  # Generates spiked buffers if the factory is valid, otherwise returns false and does nothing
  #
  # @return [Boolean] true if the operation completed successfully, false otherwise
  def save
    return false unless valid?

    @created_spiked_buffers = generate_spiked_buffers
    true
  end

  #
  # Returns the spiked_buffers that were create as part of {#save}
  # Will be an empty array if called before the #save method
  #
  # @return [Array] Array of the spiked_buffers created by the factory.
  def created_spiked_buffers
    @created_spiked_buffers || []
  end

  #
  # Returns the provided parent, or the matching tube found via the parent_barcode
  #
  # @return [Tube] The parent tube
  def parent
    @parent ||= Tube.includes(aliquots: %i[sample tag tag2]).find_by_barcode(parent_barcode)
  end

  # Validates the contents of the parent
  # The parent MUST contain one aliquot, and it MUST be a PhiX sample
  # This MAY be a stock, or a previously created spiked buffer
  def parent_contains_phi_x
    return true if parent.aliquots.one? && parent.aliquots.all? { |aliquot| aliquot.sample == PhiX.sample }

    errors.add(:parent_barcode, 'does not contain PhiX')
  end

  def tags
    i7_oligo, i5_oligo = parent.aliquots.first.tags_combination
    PhiX.tag_option_for(i7_oligo:, i5_oligo:)
  end

  private

  def phi_x_sample
    @phi_x_sample ||= PhiX.sample
  end

  # Setting the study for a SpikedBuffer tube is not currently exposed as an option through the /phi_x page
  # due to concerns that it will be set accidentally
  # But the option is here in the model to set it via study_id if needed in future
  def aliquot_attributes
    study_id.present? ? { study_id: } : {}
  end

  # Generates .number PhiX.stock_purpose tubes names
  # with name, followed by '#n' where n is the tube number (starting with 1)
  # Creates a qc_result to set the concentration (uses molarity as we're in nM not ng/ul)
  # Creates a qc_result to set the volume
  # Transfers aliquots from the parent
  def generate_spiked_buffers # rubocop:todo Metrics/AbcSize
    Array.new(number.to_i) do |index|
      spiked_buffer =
        PhiX
          .spiked_buffer_purpose
          .create!(name: "#{name} ##{index + 1}") do |tube|
            receptacle = tube.receptacle
            receptacle.qc_results.build(key: 'molarity', value: concentration, units: 'nM')
            receptacle.qc_results.build(key: 'volume', value: volume, units: 'ul')
            receptacle.transfer_requests_as_target.build(
              asset: parent.receptacle,
              target_asset: receptacle,
              aliquot_attributes:
            )
          end
      parent.children << spiked_buffer
      spiked_buffer
    end
  end
end
