# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Presenters::BatchSubmenuPresenter, type: :model do
  subject(:batch_submenu_presenter) { described_class.new(current_user, batch) }

  context 'when we are in the Ultima sequencing pipeline' do
    let(:current_user) { create(:user) }
    let(:batch) { create(:ultima_sequencing_batch) }
    let(:amp_plate_labels_option) do
      { label: 'Print AMP plate batch ID', url: "/batches/#{batch.id}/print_amp_plate_labels" }
    end

    it 'includes a link to print AMP plate labels' do
      found_amp_plate_labels_option = false

      batch_submenu_presenter.each_option do |option|
        found_amp_plate_labels_option = true if option == amp_plate_labels_option
      end

      expect(found_amp_plate_labels_option).to be true
    end
  end
end
