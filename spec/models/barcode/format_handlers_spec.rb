# frozen_string_literal: true

require 'rails_helper'

describe Barcode::FormatHandlers do
  # Set up the expectations for a valid barcode
  # @example
  #  it_has_a_valid_barcode 'DN12345S', number: 12345, prefix: 'DN', suffix: 'S'
  def self.it_has_a_valid_barcode(barcode, number: nil, prefix: nil, suffix: nil)
    context "with the barcode #{barcode}" do
      subject(:format_handler) { described_class.new(barcode) }

      it 'parses the barcode correctly', :aggregate_failures do
        expect(format_handler).to be_valid
        expect(format_handler).to have_attributes(number: number, barcode_prefix: prefix, suffix: suffix)
      end
    end
  end

  # Set up the expectations for an invalid barcode
  # @example
  #  it_has_an_invalid_barcode 'INVALID'
  def self.it_has_an_invalid_barcode(barcode)
    context "with the barcode #{barcode}" do
      subject(:format_handler) { described_class.new(barcode) }

      it { is_expected.not_to be_valid }
    end
  end

  # These groups aren't empty, we just use a helper to generate the tests
  # rubocop:disable RSpec/EmptyExampleGroup
  describe Barcode::FormatHandlers::UkBiocentreV1 do
    it_has_a_valid_barcode '1234567890NBC', prefix: nil, number: 1_234_567_890, suffix: 'NBC'
    it_has_an_invalid_barcode '123456789ANBC'
    it_has_an_invalid_barcode 'INVALID'
    it_has_an_invalid_barcode '123456789NCB'
    it_has_an_invalid_barcode '123456789MBC'
    it_has_an_invalid_barcode '1234567890ANBC'
    it_has_an_invalid_barcode 'RNA_1234'
    it_has_an_invalid_barcode ' 1234567890NBC'
    it_has_an_invalid_barcode " 1234567890NBC\na"
  end

  describe Barcode::FormatHandlers::UkBiocentreV2 do
    it_has_a_valid_barcode '123456789ANBC', prefix: nil, number: 123_456_789, suffix: 'ANBC'
    it_has_an_invalid_barcode 'INVALID'
    it_has_an_invalid_barcode '123456789NCB'
    it_has_an_invalid_barcode '123456789MBC'
    it_has_an_invalid_barcode '1234567890ANCB'
    it_has_an_invalid_barcode 'RNA_1234'
    it_has_an_invalid_barcode ' 1234567890NCB'
    it_has_an_invalid_barcode " 1234567890NCB\na"
  end

  describe Barcode::FormatHandlers::UkBiocentreV3 do
    it_has_a_valid_barcode 'RNA12345', prefix: 'RNA', number: 12_345, suffix: nil
    it_has_an_invalid_barcode '123456789ANBC'
    it_has_an_invalid_barcode 'INVALID'
    it_has_an_invalid_barcode '123456789NCB'
    it_has_an_invalid_barcode '123456789MBC'
    it_has_an_invalid_barcode '1234567890ANBC'
    it_has_an_invalid_barcode 'RNA_1234'
    it_has_an_invalid_barcode ' 1234567890NBC'
    it_has_an_invalid_barcode " 1234567890NBC\na"
  end

  describe Barcode::FormatHandlers::UkBiocentreV5 do
    it_has_a_valid_barcode 'cpRNA123456', prefix: 'cpRNA', number: 123_456, suffix: nil
    it_has_an_invalid_barcode '123456789ANBC'
    it_has_an_invalid_barcode 'INVALID'
    it_has_an_invalid_barcode '123456789NCB'
    it_has_an_invalid_barcode '123456789MBC'
    it_has_an_invalid_barcode '1234567890ANBC'
    it_has_an_invalid_barcode 'RNA_1234'
    it_has_an_invalid_barcode ' 1234567890NBC'
    it_has_an_invalid_barcode " 1234567890NBC\na"
  end

  describe Barcode::FormatHandlers::UkBiocentreUnid do
    it_has_a_valid_barcode 'RNADWP004', prefix: 'RNADWP', number: 4, suffix: nil
    it_has_an_invalid_barcode 'DNADWP004'
    it_has_an_invalid_barcode 'DNA_1234'
    it_has_an_invalid_barcode '1234567890NCB'
    it_has_an_invalid_barcode 'RNA_1234 '
    it_has_an_invalid_barcode "RNA_1234\n1"
  end

  describe Barcode::FormatHandlers::AlderlyParkV1 do
    it_has_a_valid_barcode 'RNA_1234', prefix: 'RNA', number: 1234, suffix: nil
    it_has_an_invalid_barcode 'RNA_12345'
    it_has_an_invalid_barcode 'DNA_1234'
    it_has_an_invalid_barcode '1234567890NCB'
    it_has_an_invalid_barcode 'RNA_1234 '
    it_has_an_invalid_barcode "RNA_1234\n1"
  end

  describe Barcode::FormatHandlers::AlderlyParkV2 do
    it_has_a_valid_barcode 'AP-rna-12345678', prefix: 'AP-rna', number: 12_345_678
    it_has_a_valid_barcode 'AP-rna-00110029', prefix: 'AP-rna', number: 110_029
    it_has_a_valid_barcode 'AP-kfr-00090016', prefix: 'AP-kfr', number: 90_016
    it_has_a_valid_barcode 'AP-chp-12345678', prefix: 'AP-chp', number: 12_345_678
    it_has_an_invalid_barcode 'SD-rna-1234567'
    it_has_an_invalid_barcode 'AP-rna-123456789'
    it_has_an_invalid_barcode 'AP-cdna-1234567'
    it_has_an_invalid_barcode 'AP-rna-1234567 '
    it_has_an_invalid_barcode "AP-rna-1234567\n1"
  end

  describe Barcode::FormatHandlers::CgapPlate do
    it_has_a_valid_barcode 'PLTE-1E69F5', prefix: 'PLTE', number: '1E69F5'
    it_has_an_invalid_barcode 'PLTE-1234567-'
    it_has_an_invalid_barcode 'PLATE-1234567 '
    it_has_an_invalid_barcode "PLTE-1234567\n1"
  end

  describe Barcode::FormatHandlers::Glasgow do
    it_has_a_valid_barcode 'GLA123456R', prefix: 'GLA', number: 123_456, suffix: 'R'
    it_has_a_valid_barcode 'GLA100000R', prefix: 'GLA', number: 100_000, suffix: 'R'
    it_has_an_invalid_barcode 'GLA-123456-R'
    it_has_an_invalid_barcode 'GLA123456R '
    it_has_an_invalid_barcode "GLA123456R\n1"
    it_has_an_invalid_barcode 'GLA123456S'
    it_has_an_invalid_barcode 'GLE123456R'
    it_has_an_invalid_barcode 'GLA1234567R'
  end

  describe Barcode::FormatHandlers::GlasgowV3 do
    it_has_a_valid_barcode 'GLS-GP-123456', prefix: 'GLS-GP', number: 123_456
    it_has_a_valid_barcode 'GLS-GP-1234567', prefix: 'GLS-GP', number: 1_234_567
    it_has_a_valid_barcode 'GLS-GP-12345678', prefix: 'GLS-GP', number: 12_345_678
    it_has_an_invalid_barcode 'GLS-GP-123456-R'
    it_has_an_invalid_barcode 'GLS-GP123456R '
    it_has_an_invalid_barcode "GLS-GP-123456R\n1"
    it_has_an_invalid_barcode 'GLS-GP-123456S'
  end

  describe Barcode::FormatHandlers::CambridgeAZ do
    it_has_a_valid_barcode '002107834', number: 2_107_834 # trims off the leading zeros
    it_has_a_valid_barcode '1087739333', number: 1_087_739_333
    it_has_an_invalid_barcode '12345678912'
    it_has_an_invalid_barcode 'AB1234567'
    it_has_an_invalid_barcode '002107834 '
  end

  describe Barcode::FormatHandlers::HeronTailed do
    it_has_a_valid_barcode 'HT-2107834', number: 2_107_834, prefix: 'HT'
    it_has_a_valid_barcode 'HT-111111', number: 111_111, prefix: 'HT'
    it_has_an_invalid_barcode '12345678912'
    it_has_an_invalid_barcode 'AB1234567'
    it_has_an_invalid_barcode '002107834 '
    it_has_an_invalid_barcode 'HT-123HT'
    it_has_an_invalid_barcode 'QT-123HT'
  end

  describe Barcode::FormatHandlers::Randox do
    it_has_a_valid_barcode '23JAN21-1212Q', prefix: '23JAN21', number: 1212, suffix: 'Q'
    it_has_a_valid_barcode '24JAN21-2352S', prefix: '24JAN21', number: 2352, suffix: 'S'
    it_has_an_invalid_barcode 'JAN21-1212Q'
    it_has_an_invalid_barcode '23JAN21-1212'
    it_has_an_invalid_barcode '23JAN211212Q'
    it_has_an_invalid_barcode '23JAN21-Q'
  end

  # XXX-AA-NNNNNN (where X = letter character A-Z, A = alphanumeric character A-Z/0-9, N = number character 0-9)
  describe Barcode::FormatHandlers::RandoxV2 do
    it_has_a_valid_barcode 'ABC-B1-973465', prefix: 'ABC-B1', number: 973_465
    it_has_a_valid_barcode 'BYG-1X-111222', prefix: 'BYG-1X', number: 111_222
    it_has_an_invalid_barcode 'BY-B1-973465'
    it_has_an_invalid_barcode 'aBC-B1-973465'
    it_has_an_invalid_barcode '8DS-1X-111222'
    it_has_an_invalid_barcode 'ABC-a1-973465'
    it_has_an_invalid_barcode 'ABC-B1-97346'
    it_has_an_invalid_barcode 'ABC-B1-x97346'
  end

  describe Barcode::FormatHandlers::UkBiocentreV4 do
    it_has_a_valid_barcode 'EGL000002', prefix: 'EGL', number: 2
    it_has_an_invalid_barcode 'EGL-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::CambridgeAZV2 do
    it_has_a_valid_barcode 'EGC000002', prefix: 'EGC', number: 2
    it_has_an_invalid_barcode 'EGC-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::GlasgowV2 do
    it_has_a_valid_barcode 'EGG000002', prefix: 'EGG', number: 2
    it_has_an_invalid_barcode 'EGG-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::Eagle do
    it_has_a_valid_barcode 'EGX000002', prefix: 'EGX', number: 2
    it_has_a_valid_barcode 'EGT000002', prefix: 'EGT', number: 2
    it_has_an_invalid_barcode 'EGL000002' # This is covered by UkBiocentreV4
    it_has_an_invalid_barcode 'EGC000002' # This is covered by CambridgeAZV2
    it_has_an_invalid_barcode 'EGG000002' # This is covered by GlasgowV2
    it_has_an_invalid_barcode 'EGx000002' # lowercase 3rd character
    it_has_an_invalid_barcode 'EG6000002' # numeric 3rd character
    it_has_an_invalid_barcode 'EGX-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::CambridgeAZEagle do
    it_has_a_valid_barcode 'CBE000002', prefix: 'CBE', number: 2
    it_has_an_invalid_barcode 'CBE-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::GlasgowEagle do
    it_has_a_valid_barcode 'GLS000002', prefix: 'GLS', number: 2
    it_has_an_invalid_barcode 'GLS-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::UkBiocentreEagle do
    it_has_a_valid_barcode 'EMK000002', prefix: 'EMK', number: 2
    it_has_an_invalid_barcode 'EMK-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::AlderleyParkEagle do
    it_has_a_valid_barcode 'APE000002', prefix: 'APE', number: 2
    it_has_an_invalid_barcode 'APE-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::RandoxEagle do
    it_has_a_valid_barcode 'RXE000002', prefix: 'RXE', number: 2
    it_has_an_invalid_barcode 'RXE-000002'
    it_has_an_invalid_barcode 'ABC000002'
  end

  describe Barcode::FormatHandlers::HealthServicesLaboratoriesV1 do
    it_has_a_valid_barcode 'HSL123456', prefix: 'HSL', number: 123_456, suffix: nil
    it_has_a_valid_barcode 'HSL12345678', prefix: 'HSL', number: 12_345_678, suffix: nil
    it_has_an_invalid_barcode 'HSL_123456'
    it_has_an_invalid_barcode 'INVALID'
    it_has_an_invalid_barcode '12HSL123456'
    it_has_an_invalid_barcode '123456789HSL'
    it_has_an_invalid_barcode 'RNA_1234'
    it_has_an_invalid_barcode ' HSL_123456'
    it_has_an_invalid_barcode 'HSL_123456  '
    it_has_an_invalid_barcode " 1234567890NBC\na"
  end

  describe Barcode::FormatHandlers::PlymouthV1 do
    it_has_a_valid_barcode 'PLY-chp-123456', prefix: 'PLY', number: 123_456, suffix: nil
    it_has_a_valid_barcode 'PLY-chp-12345678', prefix: 'PLY', number: 12_345_678, suffix: nil
    it_has_an_invalid_barcode 'PLY-123456'
    it_has_an_invalid_barcode 'PLY-chp-_123456'
    it_has_an_invalid_barcode 'INVALID'
    it_has_an_invalid_barcode '12PLY-chp-123456'
    it_has_an_invalid_barcode '123456789PLY-chp-'
    it_has_an_invalid_barcode 'RNA_1234'
    it_has_an_invalid_barcode ' PLY-chp-_123456'
    it_has_an_invalid_barcode 'PLY-chp-_123456  '
    it_has_an_invalid_barcode " 1234567890NBC\na"
  end

  describe Barcode::FormatHandlers::UkBiocentreV6 do
    it_has_a_valid_barcode 'RNAsst10088', prefix: 'RNAsst', number: 10_088, suffix: nil
    it_has_a_valid_barcode 'RNAsst0539473', prefix: 'RNAsst', number: 539_473, suffix: nil
    it_has_an_invalid_barcode 'RNAsst-10088'
    it_has_an_invalid_barcode 'INVALID'
  end

  describe Barcode::FormatHandlers::BrantsBridge do
    it_has_a_valid_barcode '00000000002107834', number: 2_107_834 # trims off the leading zeros
    it_has_a_valid_barcode '10877393330000001', number: 10_877_393_330_000_001
    it_has_an_invalid_barcode '12345678912'
    it_has_an_invalid_barcode 'AB123456700000001'
    it_has_an_invalid_barcode '00210783400000001 '
  end


  # rubocop:enable RSpec/EmptyExampleGroup
end
