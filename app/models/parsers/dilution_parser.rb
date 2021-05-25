# frozen_string_literal: true

# A dilution parser wraps other parsers and passes
# the relevant information on to the parent plate
# at the provided dilution factor.
class Parsers::DilutionParser
  # Parameters which get passed on unchanged
  UNSCALED = ['RIN'].freeze

  # Parameters which get multiplied by the scale factor
  SCALED = %w[concentration molarity].freeze

  # Other parameters (eg. volume) will not propagate

  attr_reader :original_parser, :scale_factor

  delegate :assay_version, to: :original_parser

  #
  # Create a parse to pass to parent plates
  # @param original_parser [#each_well_and_parameters,#assay_type,#assay_version] The original parser to scale
  # @param scale_factor [Numeric] The scale factor by which to multiply concentrations
  def initialize(original_parser, scale_factor)
    @original_parser = original_parser
    @scale_factor = scale_factor
  end

  #
  # The assay type, appending 'from -dilution' to distinguish from direct measurement
  #
  # @return [String] The name of the assay
  def assay_type
    "#{original_parser.assay_type} from dilution"
  end

  #
  # Yield each well and the scaled attributes for each
  #
  # @yield [String, Hash] Well name and a hash of attributes and their values
  def each_well_and_parameters
    original_parser.each_well_and_parameters do |well, parameters|
      adjusted_parameters = parameters.slice(*UNSCALED)
      SCALED.each do |attribute|
        adjusted_parameters[attribute] = parameters[attribute] * scale_factor if parameters[attribute]
      end
      yield well, adjusted_parameters
    end
  end
end
