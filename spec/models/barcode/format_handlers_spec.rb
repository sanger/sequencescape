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
    it_has_a_valid_barcode '1234567890NBC', prefix: nil, number: 1234567890, suffix: 'NBC'
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
    it_has_a_valid_barcode '123456789ANBC', prefix: nil, number: 123456789, suffix: 'ANBC'
    it_has_an_invalid_barcode 'INVALID'
    it_has_an_invalid_barcode '123456789NCB'
    it_has_an_invalid_barcode '123456789MBC'
    it_has_an_invalid_barcode '1234567890ANCB'
    it_has_an_invalid_barcode 'RNA_1234'
    it_has_an_invalid_barcode ' 1234567890NCB'
    it_has_an_invalid_barcode " 1234567890NCB\na"
  end

  describe Barcode::FormatHandlers::UkBiocentreV3 do
    it_has_a_valid_barcode 'RNA12345', prefix: 'RNA', number: 12345, suffix: nil
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
    it_has_a_valid_barcode 'AP-rna-12345678', prefix: 'AP-rna', number: 12345678
    it_has_a_valid_barcode 'AP-rna-00110029', prefix: 'AP-rna', number: 110029
    it_has_a_valid_barcode 'AP-kfr-00090016', prefix: 'AP-kfr', number: 90016
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
    it_has_a_valid_barcode 'GLA123456R', prefix: 'GLA', number: 123456, suffix: 'R'
    it_has_a_valid_barcode 'GLA100000R', prefix: 'GLA', number: 100000, suffix: 'R'
    it_has_an_invalid_barcode 'GLA-123456-R'
    it_has_an_invalid_barcode 'GLA123456R '
    it_has_an_invalid_barcode "GLA123456R\n1"
    it_has_an_invalid_barcode 'GLA123456S'
    it_has_an_invalid_barcode 'GLE123456R'
    it_has_an_invalid_barcode 'GLA1234567R'
  end

  describe Barcode::FormatHandlers::CambridgeAZ do
    it_has_a_valid_barcode '002107834', number: 2107834 # trims off the leading zeros
    it_has_a_valid_barcode '1087739333', number: 1087739333
    it_has_an_invalid_barcode '12345678912'
    it_has_an_invalid_barcode 'AB1234567'
    it_has_an_invalid_barcode '002107834 '
  end

  describe Barcode::FormatHandlers::HeronTailed do
    it_has_a_valid_barcode 'HT-2107834', number: 2107834, prefix: 'HT'
    it_has_a_valid_barcode 'HT-111111', number: 111111, prefix: 'HT'
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

  # XXX-AA-NNNNNNNN (where X = letter character A-Z, A = alphanumeric character A-Z/0-9, N = number character 0-9)
  describe Barcode::FormatHandlers::RandoxV2 do
    it_has_a_valid_barcode 'ABC-B1-97346572', prefix: 'ABC-B1', number: 97346572
    it_has_a_valid_barcode 'BYG-1X-11122233', prefix: 'BYG-1X', number: 11122233
    it_has_an_invalid_barcode 'BY-B1-97346572'
    it_has_an_invalid_barcode 'aBC-B1-97346572'
    it_has_an_invalid_barcode '8DS-1X-11122233'
    it_has_an_invalid_barcode 'ABC-a1-97346572'
    it_has_an_invalid_barcode 'ABC-B1-9734657'
    it_has_an_invalid_barcode 'ABC-B1-x9734657'
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
  # rubocop:enable RSpec/EmptyExampleGroup
end
