# frozen_string_literal: true

RSpec.describe Aker::ConfigParser, aker: true do
  context 'when tokenizing a line' do
    it 'returns the extracted information in an object' do
      expect(
        Aker::ConfigParser.new.tokenizer('sample_metadata.sample_common_name  <=>   common_name')
      ).to eq(
        ss: 'sample_metadata.sample_common_name', ss_name: :sample_common_name,
        ss_model: :sample_metadata, aker_name: :common_name,
        ss_to_aker: true, aker_to_ss: true
      )
    end
    it 'is able to read the direction of the arrow to understand the type of update' do
      expect(
        Aker::ConfigParser.new.tokenizer('volume  <=   volume')
      ).to eq(
        ss: 'volume', ss_name: :volume,
        ss_model: :self, aker_name: :volume,
        ss_to_aker: false, aker_to_ss: true
      )
      expect(
        Aker::ConfigParser.new.tokenizer('volume  =>   volume')
      ).to eq(
        ss: 'volume', ss_name: :volume,
        ss_model: :self, aker_name: :volume,
        ss_to_aker: true, aker_to_ss: false
      )
    end
  end
  context 'when parsing a new config description' do
    it 'returns the right config object content' do
      expect(Aker::ConfigParser.new.parse(
               %(
                 sample_metadata.gender              <=   gender
                 sample_metadata.donor_id            <=   donor_id
                 sample_metadata.phenotype           <=   phenotype
                 sample_metadata.sample_common_name  <=   common_name
                 volume                               =>  volume
                 concentration                        =>  concentration
                 amount                               =>  amount
               )
             )).to eq(
               # Maps SS models with Aker attributes
               map_ss_tables_with_aker: {
                 self: [:volume, :concentration, :amount],
                 sample_metadata: [:gender, :donor_id, :phenotype, :common_name]
               },

               # Maps SS column names from models with Aker attributes (if the name is different)
               map_aker_with_ss_columns: {
                 sample_metadata: {
                   common_name: :sample_common_name
                 }
               },

               # Aker attributes allowed to update from Aker into SS
               updatable_attrs_from_aker_into_ss: [
                 :gender, :donor_id, :phenotype, :common_name
               ],

               # Aker attributes allowed to update from SS into Aker
               updatable_attrs_from_ss_into_aker: [:volume, :concentration, :amount]
             )
    end
  end
end
