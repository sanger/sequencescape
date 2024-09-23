# frozen_string_literal: true

# {include:PhiX}
#
# PhiX::Stock acts as a factory to generate the required {LibraryTube library tubes}
class PhiX::Stock
  include ActiveModel::Model

  # @return [String] the base name for the created {LibraryTube library tubes}
  #                  Will be appended with #n to distinguish multiple tubes.
  #                  eg. ('Tube name #1', 'Tube name #2')
  attr_accessor :name

  # @return [String] The name for the set of tags to apply. eg. 'Single', 'Dual'
  #                  Valid options are taken from {PhiX.tag_option_names}
  attr_accessor :tags

  # @return [Float] The concentration of the created library in nM
  attr_accessor :concentration

  # @return [Integer] The number of {LibraryTube library tubes} to create
  attr_accessor :number

  # @return [Integer] The id of the {Study} to associate with the {Aliquot}
  attr_accessor :study_id

  validates :name, presence: true
  validates :tags, inclusion: { in: PhiX.tag_option_names.map(&:to_s) }
  validates :concentration, numericality: { greater_than: 0, only_integer: false }
  validates :number, numericality: { greater_than: 0, only_integer: true }
  validates :study_id, presence: true

  #
  # Generates stocks if the factory is valid, otherwise returns false and does nothing
  #
  # @return [Boolean] true if the operation completed successfully, false otherwise
  def save
    return false unless valid?

    @created_stocks = generate_stocks
    true
  end

  #
  # Returns the stocks that were create as part of {#save}
  # Will be an empty array if called before the #save method
  #
  # @return [Array] Array of the stocks created by the factory.
  def created_stocks
    @created_stocks || []
  end

  private

  # Generates .number PhiX.stock_purpose tubes names
  # with name, followed by '#n' where n is the tube number (starting with 1)
  # Creates a qc_result to set the concentration (uses molarity as we're in nM not ng/ul)
  # Builds tagged PhiX aliquots
  def generate_stocks # rubocop:todo Metrics/AbcSize
    Array.new(number.to_i) do |index|
      PhiX
        .stock_purpose
        .create!(name: "#{name} ##{index + 1}") do |tube|
          tube.receptacle.qc_results.build(key: 'molarity', value: concentration, units: 'nM')
          tube.receptacle.aliquots.build(sample: phi_x_sample, tag: i7_tag, tag2: i5_tag, library: tube, study_id:)
        end
    end
  end

  def phi_x_sample
    @phi_x_sample ||= PhiX.sample
  end

  # Finds or creates the i7 {Tag tag} (tag 1) according to the selected {#tags}
  # @return [Tag,nil] The selected tag, or nil if none is specified
  def i7_tag
    @i7_tag ||= PhiX.find_tag(tags, :i7_oligo)
  end

  # Finds or creates the i5 {Tag tag} (tag 2) according to the selected {#tags}
  # @return [Tag,nil] The selected tag, or nil if none is specified
  def i5_tag
    @i5_tag ||= PhiX.find_tag(tags, :i5_oligo)
  end
end
