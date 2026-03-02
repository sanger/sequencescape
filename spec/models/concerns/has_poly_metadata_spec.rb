# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HasPolyMetadata, type: :concern do
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :dummy_models, force: true do |t|
        t.string :name
      end
    end
  end
  # rubocop:enable RSpec/BeforeAfterAll

  before do
    stub_const('DummyModel', Class.new(ApplicationRecord) do
      self.table_name = 'dummy_models'
      include HasPolyMetadata
    end)
  end

  let(:model) { DummyModel.create!(name: 'Test') }

  describe '#set_poly_metadata and #get_poly_metadata' do
    context 'when value is present and key does not exist' do
      it 'creates a new PolyMetaDatum' do
        expect do
          model.set_poly_metadata('foo', 'bar')
        end.to change { model.poly_metadata.count }.by(1)
      end

      it 'sets the correct value' do
        model.set_poly_metadata('foo', 'bar')
        expect(model.get_poly_metadata('foo')).to eq('bar')
      end
    end

    context 'when value is present and key exists' do
      before { model.set_poly_metadata('foo', 'bar') }

      it 'does not create a new PolyMetaDatum' do
        expect do
          model.set_poly_metadata('foo', 'baz')
        end.not_to(change { model.poly_metadata.count })
      end

      it 'updates the value' do
        model.set_poly_metadata('foo', 'baz')
        expect(model.get_poly_metadata('foo')).to eq('baz')
      end
    end

    context 'when value is nil' do
      before { model.set_poly_metadata('foo', 'bar') }

      it 'destroys the PolyMetaDatum' do
        expect do
          model.set_poly_metadata('foo', nil)
        end.to change { model.poly_metadata.count }.by(-1)
      end

      it 'removes the value' do
        model.set_poly_metadata('foo', nil)
        expect(model.get_poly_metadata('foo')).to be_nil
      end
    end

    context 'when value is empty' do
      before { model.set_poly_metadata('foo', 'bar') }

      it 'destroys the PolyMetaDatum' do
        expect do
          model.set_poly_metadata('foo', '')
        end.to change { model.poly_metadata.count }.by(-1)
      end

      it 'removes the value' do
        model.set_poly_metadata('foo', '')
        expect(model.get_poly_metadata('foo')).to be_nil
      end
    end

    context 'when destroying a non-existent key' do
      it 'does nothing' do
        expect do
          model.set_poly_metadata('not_there', nil)
        end.not_to(change { model.poly_metadata.count })
      end
    end

    context 'when key does not exist' do
      it 'returns nil' do
        expect(model.get_poly_metadata('not_there')).to be_nil
      end
    end
  end
end
