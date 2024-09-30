# frozen_string_literal: true

require 'rails_helper'

describe IlluminaHtp::InitialStockTubePurpose do
  let(:tube_purpose) { create(:illumina_htp_initial_stock_tube_purpose) }
  let(:tube) { create(:stock_multiplexed_library_tube, purpose: tube_purpose, name: 'Current Asset') }

  describe '#sibling_tubes' do
    subject { tube_purpose.sibling_tubes(tube) }

    let(:current_submission) { create(:submission) }

    let(:parent_well) do
      well = create(:well)
      well.stock_wells << well
      well
    end

    let(:target_tube) { create(:multiplexed_library_tube) }
    let(:sibling_state) { 'pending' }
    let(:library_request) do
      create(:multiplex_request, asset: parent_well, target_asset: target_tube, submission: current_submission)
    end

    before do
      create(:transfer_request, asset: parent_well, target_asset: tube, submission: current_submission)
      library_request
      if sibling_tube
        create :transfer_request,
               asset: parents_sibling_well,
               target_asset: sibling_tube,
               submission: sibling_submission,
               state: sibling_state
      end
      create(
        :multiplex_request,
        asset: parents_sibling_well,
        target_asset: target_tube,
        submission: sibling_submission,
        request_type: sibling_request_type
      )
    end

    context 'which has been created' do
      let(:sibling_tube) { create(:stock_multiplexed_library_tube, purpose: tube_purpose, name: 'Sibling tube') }
      let(:sibling_tube_hash) do
        {
          name: sibling_tube.name,
          uuid: sibling_tube.uuid,
          ean13_barcode: sibling_tube.ean13_barcode,
          state: sibling_state
        }
      end

      context 'with siblings' do
        let(:sibling_request_type) { library_request.request_type }
        let(:sibling_submission) { current_submission }
        let(:parents_sibling_well) { create(:well) }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(subject).to be_a Array
          expect(subject).to include(sibling_tube_hash)
        end

        context 'which are a different request type' do
          # Not only is the request_type different, but so is the purpose, we also throw
          # an additional spanner in the works by adding another tube in upstream of the
          # sibling, which we don't want to show up.
          let(:sibling_tube) { create(:stock_multiplexed_library_tube, name: 'Sibling tube') }
          let(:sibling_submission) { current_submission }
          let(:sibling_request_type) { create(:multiplex_request_type) }
          let(:sibling_state) { 'started' }

          it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
            expect(subject).to be_a Array
            expect(subject).to include(sibling_tube_hash)
          end
        end

        # Okay, so maybe sibling isn't the right word here. Essentially this covers the GnT
        # pipeline where we have the following:
        #
        # P -> P -> T -> T
        #                  >-> MX
        #      P -> P -> T
        context 'which have a lineage of siblings' do
          let(:sibling_tube) { create(:stock_multiplexed_library_tube, name: 'Sibling tube') }
          let(:sibling_descendant) { create(:stock_multiplexed_library_tube, name: 'Sibling tube descendant') }
          let(:sibling_submission) { current_submission }
          let(:sibling_request_type) { create(:multiplex_request_type) }
          let(:sibling_state) { 'passed' }
          let(:sibling_descendant_hash) do
            {
              name: sibling_descendant.name,
              uuid: sibling_descendant.uuid,
              ean13_barcode: sibling_descendant.ean13_barcode,
              state: sibling_state
            }
          end

          before do
            create(
              :transfer_request,
              asset: sibling_tube,
              target_asset: sibling_descendant,
              submission: sibling_submission,
              state: 'passed'
            )
          end

          it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
            expect(subject).to be_a Array
            expect(subject).not_to include(sibling_tube_hash)
            expect(subject).to include(sibling_descendant_hash)
          end
        end
      end

      context 'with wells which are also siblings' do
        let(:sibling_request_type) { library_request.request_type }
        let(:sibling_submission) { current_submission }
        let(:sibling_tube) { create(:well) }
        let(:parents_sibling_well) { create(:well) }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(subject).to be_a Array
          expect(subject).not_to include(sibling_tube)
        end
      end

      context 'with unrelated requests out the same well' do
        let(:sibling_request_type) { library_request.request_type }
        let(:sibling_submission) { create(:submission) }
        let(:parents_sibling_well) { parent_well }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(subject).to be_a Array
          expect(subject).not_to include(sibling_tube_hash)
        end
      end

      context 'with related requests out the same well' do
        context 'which are cancelled' do
          let(:sibling_request_type) { library_request.request_type }
          let(:sibling_submission) { current_submission }
          let(:parents_sibling_well) { parent_well }
          let(:sibling_state) { 'cancelled' }

          it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
            expect(subject).to be_a Array
            expect(subject).not_to include(sibling_tube_hash)
          end
        end

        context 'which are pending' do
          # Currently these are found as siblings. This is usually a result
          # of users creating tubes multiple times. We probably COULD ignore
          # these siblings. But I'm focussing on ignoring cancelled tubes first.
        end
      end
    end

    context 'which has not been created yet' do
      let(:sibling_tube) { nil }
      let(:sibling_tube_hash) { :no_tube }

      context 'with siblings' do
        let(:sibling_request_type) { library_request.request_type }
        let(:sibling_submission) { current_submission }
        let(:parents_sibling_well) { create(:well) }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(subject).to be_a Array
          expect(subject).to include(sibling_tube_hash)
        end
      end
    end
  end
end
