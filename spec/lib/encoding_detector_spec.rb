# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EncodingDetector do
  test_strings = [
    ['ISO-8859-1',
     "This is an ISO-8859-1 string with special characters: a\xE1, e\xE9, i\xED, o\xF3, u\xB5",
     'This is an ISO-8859-1 string with special characters: aá, eé, ií, oó, uµ'],
    ['ISO-8859-1',
     "This is a Windows-1252 string with special characters \x80\xD8\xB3",
     "This is a Windows-1252 string with special characters \u0080Ø³"], # \u0080 -> Euro symbol (€)
    ['UTF-8',
     "This is a UTF-8 string with emoji \xF0\x9F\x98\x8A",
     'This is a UTF-8 string with emoji 😊'],
    ['UTF-8',
     'This is a simple ASCII string. It has no special characters making it harder to detect.',
     'This is a simple ASCII string. It has no special characters making it harder to detect.'],
    ['UTF-8',
     "Yukihiro Matsumoto \xE3\x81\xBE\xE3\x81\xA4\xE3\x82\x82\xE3\x81\xA8" \
     "\xE3\x82\x86\xE3\x81\x8D\xE3\x81\xB2\xE3\x82\x8D",
     'Yukihiro Matsumoto まつもとゆきひろ'],
    ['UTF-16',
     "\xFF\xFEH\x00e\x00l\x00l\x00o\x00 \x00w\x00o\x00r\x00l\x00d\x00!\x00 " \
     "\x00i\x00n\x00 \x00U\x00T\x00F\x00-\x001\x006\x00 \x00B\x00E\x00",
     'Hello world! in UTF-16 BE'],
    #  The test strings above are well-defined examples of their respective encodings.
    #  Real-world examples should be added below as they are encountered.
    ['ISO-8859-1',
     "log(Y) = Slope * log(x) + Offset\nParameter,Value\nSlope,1\n,Offset,3.21\n,r,0.9\n,r\xB2,0.99993\n",
     "log(Y) = Slope * log(x) + Offset\nParameter,Value\nSlope,1\n,Offset,3.21\n,r,0.9\n,r²,0.99993\n"]
  ]

  describe '#detect' do
    test_strings.each do |encoding, binary_contents, encoded_contents|
      context "when the contents are in #{encoding} encoding and should render as '#{encoded_contents}'" do
        let(:detection) { described_class.detect(binary_contents) }

        it 'detects the correct encoding' do
          expect(detection[:encoding]).to eq(encoding)
        end
      end
    end
  end

  describe '#convert_to_utf8' do
    test_strings.each do |encoding, binary_contents, encoded_contents|
      context "when the contents are in #{encoding} encoding and should render as '#{encoded_contents}'" do
        let(:converted) do
          described_class.convert_to_utf8(binary_contents.dup) # dup to unfreeze
        end

        it 'returns the contents encoding as UTF-8' do
          expect(converted.encoding.name).to eq('UTF-8')
        end

        it 'returns the contents correctly converted to UTF-8' do
          expect(converted).to eq(encoded_contents)
        end
      end
    end
  end
end
