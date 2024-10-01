# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'
require 'shared_contexts/limber_shared_context'

RSpec.describe StateChanger::InputPlate do
  let(:state_changer) do
    described_class.new(
      labware: input_plate,
      target_state: target_state,
      user: user,
      contents: contents,
      customer_accepts_responsibility: customer_accepts_responsibility
    )
  end
  let(:user) { build_stubbed(:user) }
  let(:contents) { [] }
  let(:customer_accepts_responsibility) { false }

  # A Note: In the majority of cases we don't allow state changes to be created on input
  # plates. However, there have been requests to enable the 'failure' of stock wells, so
  # it is likely we will rely on this shortly.
  #
  # Currently these changes block the update of transfer request state.
  # They would also allow failure of requests out of the wells, original added
  # to allow upfront failure decisions in bespoke (generic lims) but currently unused

  describe '#update_labware_state' do
    include_context 'a limber target plate with submissions'

    let(:target_state) { 'failed' }

    it 'fails the requests', :aggregate_failures do
      state_changer.update_labware_state

      # Requests are started and we create one event per order.
      expect(library_requests.map(&:reload)).to all(be_failed)
    end
  end
end
