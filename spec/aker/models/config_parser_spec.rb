# frozen_string_literal: true

RSpec.describe Aker::ConfigParser, aker: true do
  describe '#tokenizer' do
    it 'returns the extracted information in an object' do
      expect(
        described_class.new.tokenizer('sample_metadata.sample_common_name  <=>   common_name')
      ).to eq(
        ss: 'sample_metadata.sample_common_name', ss_name: :sample_common_name,
        ss_model: :sample_metadata, aker_name: :common_name,
        ss_to_aker: true, aker_to_ss: true
      )
    end

    it 'is able to read the direction of the arrow to understand the type of update' do
      expect(
        described_class.new.tokenizer('volume  <=   volume')
      ).to eq(
        ss: 'volume', ss_name: :volume,
        ss_model: :self, aker_name: :volume,
        ss_to_aker: false, aker_to_ss: true
      )
      expect(
        described_class.new.tokenizer('volume  =>   volume')
      ).to eq(
        ss: 'volume', ss_name: :volume,
        ss_model: :self, aker_name: :volume,
        ss_to_aker: true, aker_to_ss: false
      )
    end

    it 'gets self if there is no model defined in Sequencescape' do
      t = described_class.new.tokenizer('volume  =>   volume')
      expect(t[:ss_model]).to eq(:self)
    end
  end

  describe '#parse' do
    context 'when two colums receive the same attribute' do
      let(:my_config) do
        %(
          t1.measured_volume <=  volume
          t1.current_volume  <= volume
        )
      end

      it 'returns the list with both columns' do
        expect(described_class.new.parse(my_config)).to eq(
          map_ss_columns_with_aker: { t1: { measured_volume: [:volume], current_volume: [:volume] } },
          updatable_attrs_from_aker_into_ss: [:volume],
          updatable_columns_from_ss_into_aker: {}
        )
      end
    end

    context 'when two colums update the same attribute (WHICH IS WRONG)' do
      let(:my_config) do
        %(
          t1.measured_volume =>  volume
          t1.current_volume  => volume
        )
      end

      it 'returns the list with both columns' do
        expect(described_class.new.parse(my_config)).to eq(
          map_ss_columns_with_aker: { t1: { measured_volume: [:volume], current_volume: [:volume] } },
          updatable_attrs_from_aker_into_ss: [],
          updatable_columns_from_ss_into_aker: { t1: %i[measured_volume current_volume] }
        )
      end
    end

    context 'when two attributes update the same column (WHICH IS WRONG)' do
      let(:my_config) do
        %(
          t1.measured_volume <= volume
          t1.measured_volume <= other_volume
        )
      end

      it 'returns the list with both columns' do
        expect(described_class.new.parse(my_config)).to eq(
          map_ss_columns_with_aker: { t1: { measured_volume: %i[volume other_volume] } },
          updatable_attrs_from_aker_into_ss: %i[volume other_volume],
          updatable_columns_from_ss_into_aker: {}
        )
      end
    end

    context 'with a standard config object' do
      let(:my_config) do
        %(
          sample_metadata.gender              <=   gender
          sample_metadata.donor_id            <=   donor_id
          sample_metadata.phenotype           <=   phenotype
          sample_metadata.sample_common_name  <=   common_name
          volume                               =>  volume
          concentration                        =>  concentration
          amount                               =>  amount
        )
      end

      it 'returns the right config object content' do
        expect(described_class.new.parse(my_config)).to eq(
          map_ss_columns_with_aker: {
            sample_metadata: {
              gender: [:gender], donor_id: [:donor_id], phenotype: [:phenotype],
              sample_common_name: [:common_name]
            },
            self: {
              volume: [:volume],
              concentration: [:concentration],
              amount: [:amount]
            }
          },
          updatable_attrs_from_aker_into_ss: %i[gender donor_id phenotype common_name],
          updatable_columns_from_ss_into_aker: { self: %i[volume concentration amount] }
        )
      end
    end
  end
end
