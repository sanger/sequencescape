# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'batches/print_labels.html.erb', type: :view do
  include AuthenticatedSystem
  let(:current_user) { create(:user) }

  before do
    assign(:batch, batch)
    render
  end

  context 'when target_asset is a lane' do
    let(:lane) { create(:lane).tap { |lane| lane.labware.parents << tube } }
    let(:tube) { create(:multiplexed_library_tube) }
    let(:request) { create(:sequencing_request, target_asset: lane, asset: tube.receptacle) }
    let(:batch) { create(:batch).tap { |batch| batch.requests << request } }

    it 'shows the parent tube barcode' do
      expect(rendered).to include(tube.human_barcode)
    end
  end
end
