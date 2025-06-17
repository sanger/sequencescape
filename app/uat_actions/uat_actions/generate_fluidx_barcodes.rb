# frozen_string_literal: true

# UAT action to generate randomised FluidX barcodes in the following format:
# <prefix><random><suffix>: Ten characters in total
#   <prefix>: two uppercase letters
#   <random>: six random digits; may be truncated from the end to fit the length
#   <suffix>: <zero><index>
#     <zero>: one digit that separates random part and index, i.e. '0'
#     <index>: sequential tail, 1 to 3 digits, e.g., '9', '99', and '999'
#
# Sequential tail in barcodes may be higher and may have gaps because of
# handling duplicates.
# Random part may be truncated from right to fit the length of the barcode.
class UatActions::GenerateFluidxBarcodes < UatActions
  class_attribute :max_number_of_iterations
  self.title = 'Generate FluidX Barcodes'
  self.description = 'Generate randomised FluidX barcodes'
  self.category = :auxiliary_data
  self.max_number_of_iterations = 10

  validates :barcode_count,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 96
            }
  validates :barcode_prefix,
            presence: true,
            length: {
              is: 2
            },
            format: {
              with: /\A[A-Z]{2}\z/,
              message: 'only allows two uppercase letters'
            }
  validates :barcode_index,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 900
            }

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
    random = generate_random
    barcodes = generate_barcodes(barcode_count.to_i, barcode_prefix, random, barcode_index.to_i)
    if barcodes.size == barcode_count.to_i
      report['barcodes'] = barcodes
      true
    else
      errors.add(:base, 'Failed to generate unique barcodes')
      false
    end
  end

  # Returns a default copy of the UatAction which will be used to fill in the form.
  #
  # @return [UatActions::GenerateFluidxBarcodes] a default object for rendering a form
  def self.default
    new(barcode_count: '1', barcode_prefix: 'TS', barcode_index: '1')
  end

  private

  # Generates a random string of six digits. Each digit is randomised separately
  # for uniform distribution of digits because the string may be truncated later
  # to fit the barcode_index.
  #
  # @return [String] a random string of six digits
  def generate_random
    Array.new(6) { rand(0..9) }.join # uniform distribution of digits
  end

  # Generates an array of barcodes with the specified count, prefix, random
  # part, and starting index for the sequential tail. It attempts to generate
  # unique barcodes, iterating up to max_number_of_iterations before giving up.
  #
  # @param count [Integer] the number of barcodes to generate
  # @param prefix [String] the prefix to be used for the barcodes
  # @param random [String] random part for the barcodes
  # @param index [Integer] the starting index for the sequential tail
  # @return [Array<String>] an array of unique barcodes
  def generate_barcodes(count, prefix, random, index)
    barcodes = []
    max_number_of_iterations.times do
      # Filter out the barcodes that already exist in the database and make sure
      # there is no duplication in the generated barcodes.
      barcodes.concat(filter_barcodes(build_barcodes(count, prefix, random, index))).uniq!
      return barcodes if barcodes.size == barcode_count.to_i

      count = barcode_count.to_i - barcodes.size # More to generate.
      index += barcode_count.to_i # Continue index.
    end
  end

  # Filters out the barcodes that already exist in the database.
  #
  # @param barcodes [Array<String>] an array of barcodes
  # @return [Array<String>] an array of unique barcodes
  def filter_barcodes(barcodes)
    barcodes - Barcode.where(barcode: barcodes).pluck(:barcode)
  end

  # Builds an array of barcodes with the specified count, prefix, random
  # part, and starting index for the sequential tail.
  #
  # @param count [Integer] the number of barcodes to generate
  # @param prefix [String] the prefix to be used for the barcodes
  # @param random [String] random part for the barcodes
  # @param index [Integer] the starting index for the suffix
  # @return [Array<String>] an array of barcodes
  def build_barcodes(count, prefix, random, index)
    (index...(index + count)).map do |counter|
      suffix = "0#{counter}"
      random = random[0, 8 - suffix.length] # 8 FluidX digits minus suffix
      "#{prefix}#{random}#{suffix}"
    end
  end
end
