# frozen_string_literal: true

require 'sanger_barcode_format'
# A collection of supported formats
module Barcode::FormatHandlers
  # Include in barcode formats which can not be rendered as EAN13s
  module Ean13Incompatible
    def ean13_barcode?
      false
    end

    def ean13_barcode
      nil
    end
  end

  #
  # Base Sequencescape barcode
  # This class mostly wraps the SBCF Gem
  #
  # @author [jg16]
  #
  class SangerBase
    attr_reader :barcode_object

    def initialize(barcode)
      @barcode_object = SBCF::SangerBarcode.from_human(barcode)
    end

    delegate :human_barcode, :=~, to: :barcode_object # =~ is defined on Object, so we need to explicitly delegate
    delegate_missing_to :barcode_object

    # The gem was yielding integers for backward compatible reasons.
    # We'll convert for the time being, but should probably fix that.
    def ean13_barcode
      barcode_object.machine_barcode.to_s
    end

    def ean13_barcode?
      true
    end

    def code39_barcode?
      true
    end

    def number_as_string
      number.to_s
    end

    def code128_barcode?
      true
    end

    def barcode_prefix
      prefix.human
    end
  end

  #
  # The original Sequencescape barcode format. results in:
  # Human readable form: DN12345U
  # Ean13 compatible machine readable form: 1220012345855
  # This class mostly wraps the SBCF Gem
  #
  # @author [jg16]
  #
  class SangerEan13 < SangerBase
    # The gem was yielding integers for backward compatible reasons.
    # We'll convert for the time being, but should probably fix that.
    def machine_barcode
      ean13_barcode
    end

    alias code128_barcode machine_barcode
    alias code39_barcode machine_barcode
    alias serialize_barcode human_barcode
  end

  #
  # The revised Sequencescape barcode format. results in:
  # Human readable form: DN12345U
  # Standard code39 machine format: DN12345U
  # Ean13 fallback: 1220012345855
  # This class mostly wraps the SBCF Gem
  #
  # @author [jg16]
  #
  class SangerCode39 < SangerBase
    def machine_barcode
      human_barcode
    end

    alias code128_barcode machine_barcode
    alias code39_barcode machine_barcode
    alias serialize_barcode human_barcode
  end

  # A basic class for barodes that can be validated and decomposed by simple regular expressions
  # Classes that inherit from this should define a regular expression with optional names matchers
  # for prefix, number and suffix. This regex should be assigned to self.format
  class BaseRegExBarcode
    include Ean13Incompatible

    attr_reader :human_barcode

    class_attribute :format

    def initialize(barcode)
      @human_barcode = barcode
      @matches = format.match(@human_barcode)
    end

    def barcode_prefix
      @matches[:prefix] if @matches&.names&.include?('prefix')
    end

    def number
      @matches[:number].to_i if @matches&.names&.include?('number')
    end

    def suffix
      @matches[:suffix] if @matches&.names&.include?('suffix')
    end

    def child
      @matches[:child].to_i if @matches&.names&.include?('child') && !@matches[:child].nil?
    end

    def code128_barcode?
      /\A[[:ascii:]]+\z/.match?(@human_barcode)
    end

    def code39_barcode?
      %r{\A[A-Z0-9 \-.$/+%]+\z}.match?(@human_barcode)
    end

    def valid?
      format.match? @human_barcode
    end

    def code128_barcode
      human_barcode if code128_barcode?
    end

    def code39_barcode
      human_barcode if code39_barcode?
    end

    def =~(other)
      human_barcode == other
    end

    alias machine_barcode human_barcode
    alias serialize_barcode human_barcode
  end

  # Added to support plate barcodes from baracoda
  # Expected formats:
  # <prefix>-<text>-nnn-<suffix>... where n is a digit.
  # prefix is dependent on plate_barcode_prefix environment variable
  # Examples: SQPP-T23-2343-Q, SQPP-2343-R, SQPP-2343
  class Sequencescape22 < BaseRegExBarcode
    prefix = configatron.plate_barcode_prefix

    self.format =
      /\A(?<prefix>#{prefix})(-[a-zA-Z0-9_]{1,3})?-(?<number>[0-9]+)(-(?<child>[0-9]+))?(-(?<suffix>[A-Z]))?\z/
  end

  # Infinium barcodes are externally generated barcodes on Illumina Infinium chips
  class Infinium < BaseRegExBarcode
    # Based on ALL existing examples (bar what appears to be accidental usage of the sanger barcode in 5 cases)
    # eg. WG0000001-DNA and WG0000001-BCD
    self.format = /\A(?<prefix>WG)(?<number>[0-9]{7})-(?<suffix>[DNA|BC]{3})\z/
  end

  # Fluidigm barcodes are externally generated barcodes present on fluidigm plates. They are ten digits long.
  class Fluidigm < BaseRegExBarcode
    # Ten digit barcode
    self.format = /\A(?<number>[0-9]{10})\z/
  end

  # External barcodes are almost always valid.
  class External < BaseRegExBarcode
    # Extract prefix numbers and suffix if the format is fairly simple.
    # - A number, surrounded by JUST letters and underscores
    self.format = /\A(?<prefix>[\w&&[^\d]]*)(?<number>\d+)(?<suffix>[\w&&[^\d]]*)\z/

    def valid?
      true
    end
  end

  # CGAP barcodes are externally generated foreign barcodes.
  class Cgap < BaseRegExBarcode
    # They have a prefix 'CGAP-', then a hex number that will grow in length.
    # The last character is a checksum hex digit.
    self.format = /\A(?<prefix>CGAP-)(?<number>[0-9a-fA-F]+)(?<suffix>[0-9a-fA-F])\z/

    def number
      # number is a hexadecimal string here
      @matches[:number] if @matches&.names&.include?('number')
    end
  end

  # CGAP plate barcodes are generated by the CGAP LIMS
  class CgapPlate < BaseRegExBarcode
    # They have a prefix 'PLTE-', then a hex number that will grow in length.
    # The last character is a checksum hex digit.
    self.format = /\A(?<prefix>PLTE)-(?<number>[0-9a-fA-F]+)\z/

    def number
      # number is a hexadecimal string here
      @matches[:number] if @matches&.names&.include?('number')
    end
  end

  # CGAP rack barcodes are generated by the CGAP LIMS
  class CgapRack < BaseRegExBarcode
    # They have a prefix 'RACK-', then a hex number that will grow in length.
    # The last character is a checksum hex digit.
    self.format = /\A(?<prefix>RACK)-(?<number>[0-9a-fA-F]+)\z/

    def number
      # number is a hexadecimal string here
      @matches[:number] if @matches&.names&.include?('number')
    end
  end

  # FluidX barcodes matches a prefix of any two letters and an eight digit
  # number. No suffix.
  class FluidxBarcode < BaseRegExBarcode
    self.format = /\A(?<prefix>[A-Za-z]{2})(?<number>\d{8})\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # nnnnnnnnnnNBC (Early UK Biocenter)
  # where n is a digit
  class UkBiocentreV1 < BaseRegExBarcode
    self.format = /\A(?<number>\d{9,11})(?<suffix>NBC)\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # nnnnnnnnnANBC (Later UK Biocenter)
  # where n is a digit
  class UkBiocentreV2 < BaseRegExBarcode
    self.format = /\A(?<number>\d{9,10})(?<suffix>ANBC)\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Format identified during validation:
  # RNADWPnnn
  class UkBiocentreUnid < BaseRegExBarcode
    self.format = /\A(?<prefix>RNADWP)(?<number>\d{3})\z/
  end

  # Added to support plates from Alderley park:
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # RNA_nnnn (Early Alderley park: Temporary barcodes on early plates)
  class AlderlyParkV1 < BaseRegExBarcode
    self.format = /\A(?<prefix>RNA)_(?<number>\d{4})\z/
  end

  # Added to support plates from Alderley park:
  # as part of project Heron
  # See issue: https://github.com/sanger/sequencescape/issues/2634
  # Expected formats:
  # AP-ccc-nnnnnnnn (Later Alderley park: The new permanent barcodes are AP-rna-00110029
  #                @note some RNA plates had the AP-kfr-00090016 barcode applied in error
  class AlderlyParkV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>AP-[a-z]{3})-(?<number>\d{8})\z/
  end

  # Added to support plates from UK Biocentre https://www.ukbiocentre.com/
  # as part of project Heron
  # Expected formats:
  # RNAnnnnnnnnn
  # where n is a digit
  class UkBiocentreV3 < BaseRegExBarcode
    self.format = /\A(?<prefix>RNA)(?<number>\d+)\z/
  end

  # Expected formats:
  # cpRNAnnnnnn
  # where n is a digit
  class UkBiocentreV5 < BaseRegExBarcode
    self.format = /\A(?<prefix>cpRNA)(?<number>\d+)\z/
  end

  # Added to support plates from Queen Elizabeth University Hospital
  # as part of project Heron
  # Expected formats:
  # GLAnnnnnnR
  # where n is a digit
  class Glasgow < BaseRegExBarcode
    self.format = /\A(?<prefix>GLA)(?<number>[0-9]{6})(?<suffix>R)\z/
  end

  # Added to support plates from Cambridge AZ
  # as part of project Heron
  # Expected formats:
  # nnnnnnnnn, nnnnnnnnnn
  # where n is a digit
  class CambridgeAZ < BaseRegExBarcode
    self.format = /\A(?<number>[0-9]{9,10})\z/
  end

  # Added to support destination plates for Beckman driven
  # cherrypick process as part of project Heron.
  # Expected formats:
  # HT-nnnnnn where n is a digit.
  # Numeric component will be at least 6 digits long, but may eventually hit more
  class HeronTailed < BaseRegExBarcode
    self.format = /\A(?<prefix>HT)-(?<number>[0-9]{6,})\z/
  end

  # Added to support plates from Randox
  # as part of project Heron
  # Expected formats:
  # DDMMMYY-TTTTs
  # where DDMMMYY is the date e.g. 23JAN21
  # TTTT is the time e.g. 1431
  # and s is an upper case letter e.g. Q
  class Randox < BaseRegExBarcode
    self.format = /\A(?<prefix>\d{2}[A-Z]{3}\d{2})-(?<number>\d{4})(?<suffix>[A-Z])\z/
  end

  # XXX-AA-NNNNNN
  # where:
  #  X = letter character A-Z
  #  A = alphanumeric character A-Z/0-9
  #  N = number character 0-9
  class RandoxV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>[A-Z]{3}-[A-Z0-9]{2})-(?<number>\d{6})\z/
  end

  # Added to support 'Operation Eagle' plates from UK Biocentre
  # as part of project Heron
  # Expected formats:
  # EGLnnnnnn
  # where n is a digit
  class UkBiocentreV4 < BaseRegExBarcode
    self.format = /\A(?<prefix>EGL)(?<number>\d{6})\z/
  end

  # Added to support 'Operation Eagle' plates from Cambridge AZ
  # as part of project Heron
  # Expected formats:
  # EGCnnnnnn
  # where n is a digit
  class CambridgeAZV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>EGC)(?<number>\d{6})\z/
  end

  # Added to support 'Operation Eagle' plates from Glasgow
  # as part of project Heron
  # Expected formats:
  # EGGnnnnnn
  # where n is a digit
  class GlasgowV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>EGG)(?<number>\d{6})\z/
  end

  # Expected formats:
  # GLS-GP-nnnnnn
  # where n is a digit
  class GlasgowV3 < BaseRegExBarcode
    self.format = /\A(?<prefix>GLS-GP)-(?<number>\d{6,})\z/
  end

  # Added to support 'Operation Eagle' plates
  # except the ones already categorised (MK, CM and GLS)
  # as part of project Heron
  # Expected formats:
  # EG?nnnnnn
  # where n is a digit
  # and ? is any uppercase letter
  class Eagle < BaseRegExBarcode
    self.format = /\A(?<prefix>EG(?![LCG])[A-Z])(?<number>\d{6})\z/
  end

  # Added to support Cambridge 'Operation Eagle' plates
  # as part of project Heron
  # Expected formats:
  # CBEnnnnnn
  # where n is a digit
  class CambridgeAZEagle < BaseRegExBarcode
    self.format = /\A(?<prefix>CBE)(?<number>\d{6})\z/
  end

  # Added to support Glasgow 'Operation Eagle' plates
  # as part of project Heron
  # Expected formats:
  # GLSnnnnnn
  # where n is a digit
  class GlasgowEagle < BaseRegExBarcode
    self.format = /\A(?<prefix>GLS)(?<number>\d{6})\z/
  end

  # Added to support UkBiocentre 'Operation Eagle' plates
  # as part of project Heron
  # Expected formats:
  # EMKnnnnnn
  # where n is a digit
  class UkBiocentreEagle < BaseRegExBarcode
    self.format = /\A(?<prefix>EMK)(?<number>\d{6})\z/
  end

  # Added to support Alderley Park 'Operation Eagle' plates
  # as part of project Heron
  # Expected formats:
  # APEnnnnnn
  # where n is a digit
  class AlderleyParkEagle < BaseRegExBarcode
    self.format = /\A(?<prefix>APE)(?<number>\d{6})\z/
  end

  # Added to support Randox 'Operation Eagle' plates
  # as part of project Heron
  # Expected formats:
  # RXEnnnnnn
  # where n is a digit
  class RandoxEagle < BaseRegExBarcode
    self.format = /\A(?<prefix>RXE)(?<number>\d{6})\z/
  end

  # Expected formats:
  # HSLnnnnnn
  # where n is a digit
  class HealthServicesLaboratoriesV1 < BaseRegExBarcode
    self.format = /\A(?<prefix>HSL)(?<number>\d+)\z/
  end

  # Expected formats:
  # PLY-chp-nnnnnnn
  # where n is a digit
  class PlymouthV1 < BaseRegExBarcode
    self.format = /\A(?<prefix>PLY)-chp-(?<number>\d+)\z/
  end

  # This format was used by the Plymouth LHL for sending non-cherrypicked
  # samples to Sanger.
  #
  # Expected formats:
  # BnnnnnnRNAEXT
  # where n is a digit
  class PlymouthV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>B)(?<number>\d{6})(?<suffix>RNAEXT)\z/
  end

  # Added to support 3 ad hoc plates from UK Biocentre
  # as part of project Heron
  # Expected formats:
  # RNAsstnnnnn
  # where n is a digit
  class UkBiocentreV6 < BaseRegExBarcode
    self.format = /\A(?<prefix>RNAsst)(?<number>\d+)\z/
  end

  # Support for Brants Bridge centre
  # Expected formats:
  # nnnnnnnnnnnnnnnnn
  # where n is a digit
  class BrantsBridge < BaseRegExBarcode
    self.format = /\A(?<number>[0-9]{17})\z/
  end

  # Added to support Brants Bridge centre V2
  # They have a prefix 'BB', then a number of any length.
  # Expected formats:
  # BB-nnnnnnnnn
  # where n is a digit
  # See issue: https://github.com/sanger/sequencescape/issues/3329
  class BrantsBridgeV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>BB)-(?<number>\d+)\z/
  end

  # Support for Brants Bridge centre unconsolidated plates from July 2023
  #
  # Expected formats:
  # nnnnnnnDWP
  # where n is a digit
  class BrantsBridgeV3 < BaseRegExBarcode
    self.format = /\A(?<number>\d{7})(?<suffix>DWP)\z/
  end

  # Support for Leamington Spa centre
  # Expected formats:
  # CHERYnnnnnn
  # where n is a digit
  class LeamingtonSpa < BaseRegExBarcode
    self.format = /\A(?<prefix>CHERY)(?<number>\d+)\z/
  end

  # Support for Leamington Spa centre
  #
  # Expected formats:
  # RFLCPnnnnnnnn
  # where n is a digit
  class LeamingtonSpaV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>RFLCP)(?<number>\d{8})\z/
  end

  # This format was used by the Leamington Spa LHL for sending non-cherrypicked
  # samples to Sanger.
  #
  # Expected formats:
  # ELUTEnnnnnnnn
  # where n is a digit
  class LeamingtonSpaV3 < BaseRegExBarcode
    self.format = /\A(?<prefix>ELUTE)(?<number>\d{8})\z/
  end

  # Support for Newcastle centre
  # Expected formats:
  # ICHNEnnnnnc
  # where n is a digit
  # and c is a letter
  class Newcastle < BaseRegExBarcode
    self.format = /\A(?<prefix>ICHNE)(?<number>\d+)(?<suffix>[A-Z|a-z]{1})\z/
  end

  # Support for UK Biocentre
  # As part of the Cardinal pipeline
  # Expected formats:
  # 003nnnnnnnnnn
  # where n is a digit
  class UkBiocentreV7 < BaseRegExBarcode
    self.format = /\A(?<prefix>003)(?<number>[0-9]{10})\z/
  end

  # Support for East London Genes and Health
  # As part of the Cardinal pipeline
  # To allow import Cardinal blood vacutainer tubes into Sequencescape
  # See issue: https://github.com/sanger/limber/issues/822
  # Expected formats:
  # S2-046-nnnnnn
  # where n is a digit
  class EastLondonGenesAndHealth < BaseRegExBarcode
    self.format = /\A(?<prefix>S2)-046-(?<number>\d+)\z/
  end

  # Support for East London Genes and Health
  # As part of the Cardinal pipeline, as above
  # Expected formats:
  # S2-nnn-nnnnnn
  # where n is a digit
  # This is needed in addition to the above because the middle section represents the study
  # in ELGH's system, and some participants come in under a different primary study.
  class EastLondonGenesAndHealthV2 < BaseRegExBarcode
    self.format = /\A(?<prefix>S2)-\d+-(?<number>\d+)\z/
  end

  # Support for Code128 barcodes supplied by CILS for the IBD Response study.
  # Added as part of the scRNA Core pipeline
  # Expected formats:
  # IBDRnnnnnn
  # where n is a digit
  class IbdResponse < BaseRegExBarcode
    self.format = /\A(?<prefix>IBDR)(?<number>[0-9]{6})\z/
  end

  # Support for RVI barcodes.
  # Expected formats:
  # RVI-nnnnnn
  # where n is a digit
  class Rvi < BaseRegExBarcode
    self.format = /\A(?<prefix>RVI)-(?<number>[0-9]{6,})\z/
  end

  #  add AkerBarcode class here as it could be called in
  #  Barcode::FormatHandlers.const_get in app/models/barcode.rb to avoid
  #  uninitialized constant Barcode::FormatHandlers::AkerBarcode (NameError)
  class AkerBarcode < BaseRegExBarcode
    self.format = /\A(?<prefix>Aker)-(?<number>[0-9]{2,})\z/
  end
end
