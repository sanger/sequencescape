# frozen_string_literal: true

shared_examples 'a mapping between an Aker model and Sequencescape', aker: true do
  context 'with a custom config' do
    before do
      Aker::Mapping.config = my_config
    end

    context 'with private methods' do
      describe '#table_names_for_attr' do
        it 'gives back a table name from an attribute name' do
          expect(mapping.send(:table_names_for_attr, :volume)).to eq([:well_attribute])
        end
      end

      describe '#mapped_setting_attributes_for_table' do
        it 'filters out the attributes that do not belong to the table' do
          expect(mapping.send(:mapped_setting_attributes_for_table, :sample_metadata, gender: 'Male', volume: 33)).to eq(gender: 'Male')
        end

        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:mapped_setting_attributes_for_table, :well_attribute, gender: 'Male', volume: 33)).to eq(measured_volume: 33)
        end
      end

      describe '#columns_for_table_from_field' do
        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:columns_for_table_from_field, :well_attribute, :volume)).to eq([:measured_volume])
        end

        context 'when two colums receive the same attribute' do
          let(:my_config) do
            %(
              well_attribute.measured_volume <= volume
              well_attribute.current_volume  <= volume
            )
          end

          it 'returns the list with both colums' do
            expect(mapping.send(:columns_for_table_from_field, :well_attribute, :volume)).to eq(%i[measured_volume current_volume])
          end
        end
      end
    end
  end
end
