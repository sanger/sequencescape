# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Concerns::Contents, :heron, :lighthouse, type: :model do
  require 'rspec/mocks/standalone'
  let(:factory_klass) do
    Class.new do
      include ActiveModel::Model
      include Heron::Factories::Concerns::CoordinatesSupport
      include Heron::Factories::Concerns::RecipientsCoordinates
      include Heron::Factories::Concerns::Contents

      def initialize(params)
        @params = params
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end

      def content_factory
        Heron::Factories::Sample
      end

      def recipients_key
        :wells
      end
    end
  end
  let(:factory) { factory_klass.new(params) }
  let(:study) { create(:study) }

  include BarcodeHelper

  before { mock_plate_barcode_service }

  context 'with valid params' do
    let(:params) { { wells: {}, study_uuid: study.uuid } }

    it 'can build a valid content factory' do
      expect(factory).to be_valid
    end
  end

  context 'with invalid params' do
    context 'when keys are not valid coordinates' do
      let(:params) { { wells: { test1: [], B01: [], test2: [] }, study_uuid: study.uuid } }

      it 'is not valid' do
        factory = factory_klass.new(params)
        expect(factory).not_to be_valid
      end

      it 'gets an error message about it for each wrong location' do
        factory = factory_klass.new(params)
        factory.validate
        expect(factory.errors.full_messages.uniq).to eq(
          [
            'Coordinate The location "test1" has an invalid format',
            'Coordinate The location "test2" has an invalid format'
          ]
        )
      end
    end

    context 'when the samples do not have a study' do
      let(:study) { create(:study) }
      let(:sample) { create(:sample) }
      let(:params) { { wells: { A1: { content: {} } } } }

      it 'is not valid' do
        factory = factory_klass.new(params)
        expect(factory).not_to be_valid
      end

      context 'when supplying the study_uuid' do
        it 'is valid' do
          params[:study_uuid] = study.uuid
          factory = factory_klass.new(params)
          expect(factory).to be_valid
        end
      end
    end

    context 'when the samples have wrong fields' do
      let(:study) { create(:study) }
      let(:sample) { create(:sample) }
      let(:params) do
        {
          wells: {
            A1: {
              content: [
                { phenotype: 'Another phenotype', study_uuid: study.uuid },
                { phenotype: 'A phenotype', study_uuid: study.uuid }
              ]
            },
            B1: {
              content: [
                { phenotype: 'Right', study_uuid: study.uuid },
                { sample_uuid: sample.uuid, phenotype: 'wrong' }
              ]
            },
            C1: {
              content: {
                phenotype: 'Right',
                asdf: 'wrong'
              }
            }
          }
        }
      end

      it 'is not valid' do
        factory = factory_klass.new(params)
        expect(factory).not_to be_valid
      end

      it 'gets an error message about it for each wrong sample' do
        expect(factory_klass.new(params).tap(&:validate).errors.full_messages.uniq).to eq(
          [
            'Content b1, pos: 1 ["Phenotype No other params can be added when sample uuid specified"]',
            "Content c1 [\"Study can't be blank\", \"Asdf Unexisting field for sample or sample_metadata\"]"
          ]
        )
      end
    end
  end

  describe '#add_aliquots_into_locations' do
    shared_examples_for 'I can add aliquots into each location' do
      context 'when receiving empty config' do
        let(:params) { {} }

        it 'does nothing' do
          expect { factory.add_aliquots_into_locations(containers_for_locations) }.not_to change(Aliquot, :count)
        end
      end

      context 'when providing samples information' do
        let!(:sample) { create(:sample) }
        let(:params) do
          {
            wells: {
              A01: {
                content: {
                  phenotype: 'A phenotype',
                  study_uuid: study.uuid
                }
              },
              B01: {
                content: {
                  phenotype: 'A phenotype',
                  study_uuid: study.uuid
                }
              },
              C01: {
                content: {
                  sample_uuid: sample.uuid
                }
              }
            },
            study_uuid: study.uuid
          }
        end

        it 'is valid' do
          expect(factory).to be_valid
        end

        it 'creates the new aliquots' do
          expect { factory.add_aliquots_into_locations(containers_for_locations) }.to change(Sample, :count).by(2).and(
            change(Aliquot, :count).by(3)
          )
        end

        context 'when it creates more than one aliquot in the same location' do
          let(:params) do
            {
              wells: {
                A01: {
                  content: [
                    { phenotype: 'A phenotype', aliquot: { tag_id: 1 }, study_uuid: study.uuid },
                    { sample_uuid: sample.uuid, aliquot: { tag_id: 2 } }
                  ]
                },
                B01: {
                  content: {
                    phenotype: 'A phenotype',
                    study_uuid: study.uuid
                  }
                },
                C01: {
                  content: {
                    sample_uuid: sample.uuid
                  }
                }
              },
              study_uuid: study.uuid
            }
          end

          it 'is valid' do
            expect(factory).to be_valid
          end

          it 'creates the right number of elements' do
            expect { factory.add_aliquots_into_locations(containers_for_locations) }.to change(Sample, :count).by(
              2
            ).and(change(Aliquot, :count).by(4))
          end

          it 'creates the right aliquots for A1' do
            factory.add_aliquots_into_locations(containers_for_locations)

            expect(containers_for_locations['A1'].aliquots.count).to eq(2)
            expect(containers_for_locations['A1'].aliquots.last.sample).to eq(sample)
          end

          it 'creates the right aliquots for B1' do
            factory.add_aliquots_into_locations(containers_for_locations)
            expect(containers_for_locations['B1'].aliquots.count).to eq(1)
          end

          it 'creates the right aliquots for C1' do
            factory.add_aliquots_into_locations(containers_for_locations)
            expect(containers_for_locations['C1'].aliquots.count).to eq(1)
            expect(containers_for_locations['C1'].aliquots.first.sample).to eq(sample)
          end
        end
      end
    end

    context 'with a tube rack' do
      let(:purpose) { create(:tube_rack_purpose, target_type: 'TubeRack', name: 'Stock Tube Rack', size: '96') }
      let(:tube_rack) { TubeRack.create!(size: '96', purpose: purpose) }
      let(:tubes) do
        %w[A1 B1 C1].map do |coordinate|
          tube = create(:tube)
          create(:racked_tube, tube:, coordinate:, tube_rack:)
          tube
        end
      end
      let(:containers_for_locations) { { 'A1' => tubes[0], 'B1' => tubes[1], 'C1' => tubes[2] } }

      it_behaves_like 'I can add aliquots into each location'
    end

    context 'with a plate' do
      let(:purpose) { create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96') }
      let(:plate) { purpose.create! }
      let(:containers_for_locations) do
        {
          'A1' => plate.wells.located_at('A1').first,
          'B1' => plate.wells.located_at('B1').first,
          'C1' => plate.wells.located_at('C1').first
        }
      end

      it_behaves_like 'I can add aliquots into each location'
    end
  end
end
