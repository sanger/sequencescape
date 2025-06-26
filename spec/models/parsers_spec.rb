# frozen_string_literal: true

describe Parsers do
  describe '#self.parser_for' do
    context 'when the file does not appear to be a CSV' do
      it 'returns nil' do
        parser = described_class.parser_for('qc_file.txt', 'text/plain', "A1,A2,A3\n1,2,3\n4,5,6\n")
        expect(parser).to be_nil
      end
    end

    context 'when a parser claims to parse the CSV file' do
      let(:valid_parser) { Parsers::PARSERS.sample }

      before { allow(valid_parser).to receive(:parses?).and_return(true) }

      it 'returns a parser for the CSV' do
        parser = described_class.parser_for('qc_file.csv', 'text/csv', "A1,A2,A3\n1,2,3\n4,5,6\n")
        expect(parser).to be_a(valid_parser)
      end

      context 'when all other parsers raise exceptions' do
        before do
          Parsers::PARSERS.each do |parser|
            next if parser == valid_parser

            allow(parser).to receive(:parses?).and_raise(StandardError)
          end
        end

        it 'still returns the parser that claims to parse the CSV' do
          parser = described_class.parser_for('qc_file.csv', 'text/csv', "A1,A2,A3\n1,2,3\n4,5,6\n")
          expect(parser).to be_a(valid_parser)
        end
      end
    end

    context 'when the CSV file is not parsable by any known parser' do
      before { Parsers::PARSERS.each { |parser| allow(parser).to receive(:parses?).and_return(false) } }

      it 'returns nil' do
        parser = described_class.parser_for('qc_file.csv', 'text/csv', "A1,A2,A3\n1,2,3\n4,5,6\n")
        expect(parser).to be_nil
      end
    end
  end
end
