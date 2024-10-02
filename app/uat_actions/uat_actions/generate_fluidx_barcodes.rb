# frozen_string_literal: true

# UAT action to generate randomised FluidX barcodes.
class UatActions::GenerateFluidxBarcodes < UatActions
  self.title = 'Generate FluidX Barcodes'
  self.description = 'Generate randomised FluidX barcodes'
  self.category = :auxiliary_data

  validates :barcode_count, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 96 }
  validates :barcode_prefix,
            presence: true,
            length: {
              is: 2
            },
            format: {
              with: /\A[A-Z]{2}\z/,
              message: 'only allows two uppercase letters'
            }
  validates :barcode_index, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 900 }

  form_field :barcode_count,
             :number_field,
             label: 'Number of barcodes',
             help: 'The number of FluidX barcodes that should be generated',
             options: {
               min: 1,
               max: 96,
               value: 1
             }
  form_field :barcode_prefix,
             :text_field,
             label: 'Barcode prefix',
             help: 'The prefix to be used for the barcodes',
             options: {
               maxlength: 2,
               oninput: 'javascript:this.value=this.value.toUpperCase().replace(/[^A-Z]/g, "")',
               value: 'TS'
             }
  form_field :barcode_index,
             :number_field,
             label: 'Barcode index',
             help: 'The starting index to make a sequential tail for the barcodes',
             options: {
               min: 1,
               max: 900,
               value: 1
             }

  # This method is called from the save method after validations have passed.
  # If the return value is true, the report hash populated by the action is
  # used for rendering the response. If the return value is false, the errors
  # collection is used.
  #
  # @return [Boolean] true if the action was successful; false otherwise
  def perform
    random = Array.new(6) { rand(0..9) }.join # uniform distribution of digits
    barcodes = generate_barcodes(barcode_count.to_i, barcode_prefix, random, barcode_index.to_i)
    if barcodes.size == barcode_count.to_i
      report['barcodes'] = barcodes
      true
    else
      errors.add(:base, 'Failed to generate unique barcodes')
      false
    end
  end

  private

  # Generates an array of barcodes with the specified count, prefix, common
  # random part, and starting index for the sequential tail. It attempts to
  # generate unique barcodes, iterating up to 5 times before giving up.
  #
  # @param count [Integer] the number of barcodes to generate
  # @param prefix [String] the prefix to be used for the barcodes
  # @param random [String] a common random part for the barcodes
  # @param index [Integer] the starting index for the sequential tail
  # @return [Array<String>] an array of unique barcodes
  # @raise [StandardError] if it fails to generate unique barcodes
  def generate_barcodes(count, prefix, random, index)
    barcodes = []
    5.times do # Max 5 iterations to generate unique barcodes.
      barcodes.concat(filter_barcodes(build_barcodes(count, prefix, random, index)))
      return barcodes if barcodes.size == barcode_count.to_i
      count = barcode_count.to_i - barcodes.size
      index += count
    end
  end

  # Filters out the barcodes that already exist in the database.
  #
  # @param barcodes [Array<String>] an array of barcodes
  # @return [Array<String>] an array of unique barcodes
  def filter_barcodes(barcodes)
    barcodes - Barcode.where(barcode: barcodes).pluck(:barcode)
  end

  # Builds an array of barcodes with the specified count, prefix, common
  # random part, and starting index for the sequential tail.
  #
  # @param count [Integer] the number of barcodes to generate
  # @param prefix [String] the prefix to be used for the barcodes
  # @param random [String] a common random part for the barcodes
  # @param index [Integer] the starting index for the suffix
  # @return [Array<String>] an array of barcodes
  def build_barcodes(count, prefix, random, index)
    (index...(index + count)).map do |counter|
      suffix = counter.to_s.rjust(2, '0') # Min 2 suffix digits
      random = random[0, 8 - suffix.length] # 8 FluidX digits minus suffix
      "#{prefix}#{random}#{suffix}"
    end
  end
end
