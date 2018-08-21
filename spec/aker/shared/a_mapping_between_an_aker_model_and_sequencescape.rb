# frozen_string_literal: true

shared_examples 'a mapping between an Aker model and Sequencescape', aker: true do
  context 'with a custom config' do
    before do
      Aker::Mapping.config = my_config
    end

    context 'with private methods' do
      context '#table_for_attr' do
        it 'gives back a table name from an attribute name' do
          expect(mapping.send(:table_for_attr, :volume)).to eq(:well_attribute)
        end
        it 'returns :self if there is no table for the attribute' do
          expect(mapping.send(:table_for_attr, :volumes)).to eq(:self)
        end
      end

      context '#attributes_for_table' do
        it 'filters out the attributes that do not belong to the table' do
          expect(mapping.send(:attributes_for_table, :sample_metadata, gender: 'Male', volume: 33)).to eq(gender: 'Male')
        end
        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:attributes_for_table, :well_attribute, gender: 'Male', volume: 33)).to eq(measured_volume: 33)
        end
      end

      context '#valid_attrs' do
        it 'filters out the attributes that do not have a valid key' do
          expect(mapping.send(:valid_attrs, :sample_metadata, [:gender], gender: 'Male', volume: 33)).to eq(gender: 'Male')
        end

        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:valid_attrs, :well_attribute, [:volume], gender: 'Male', volume: 33)).to eq(measured_volume: 33)
        end
      end

      context '#aker_attr_name' do
        it 'translates the valid attribute to the SS nomenclature using the config ' do
          expect(mapping.send(:aker_attr_name, :well_attribute, :volume)).to eq(:measured_volume)
        end
        it 'returns the passed attr name when no translation is defined for the attribute ' do
          expect(mapping.send(:aker_attr_name, :well_attribute, :volume2)).to eq(:volume2)
        end
        it 'returns the passed attr name when no model translation is defined' do
          expect(mapping.send(:aker_attr_name, :unknown_model, :unknown_attribute)).to eq(:unknown_attribute)
        end
      end
    end
  end
end
