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
    let(:amp_plate_verify_option) do
      { label: 'Verify AMP plate layout', url: "/batches/#{batch.id}/verify?verification_flavour=amp_plate" }
    end
    let(:tube_verify_option) do
      { label: 'Verify tube layout', url: "/batches/#{batch.id}/verify?verification_flavour=tube" }
    end

    before do
      allow(batch_submenu_presenter.ability).to receive(:can?).and_return(true)
    end

    it 'includes a link to print AMP plate labels' do
      found_amp_plate_labels_option = false

      batch_submenu_presenter.each_option do |option|
        found_amp_plate_labels_option = true if option == amp_plate_labels_option
      end

      expect(found_amp_plate_labels_option).to be true
    end

    it 'includes a link to verify AMP plates' do
      found_amp_plate_verify_option = false

      batch_submenu_presenter.each_option do |option|
        found_amp_plate_verify_option = true if option == amp_plate_verify_option
      end

      expect(found_amp_plate_verify_option).to be true
    end

    it 'includes a link to verify tubes' do
      found_tube_verify_option = false

      batch_submenu_presenter.each_option do |option|
        found_tube_verify_option = true if option == tube_verify_option
      end

      expect(found_tube_verify_option).to be true
    end

    context 'when layout has already been verified' do
      before do
        batch.lab_events.create!(description: 'Tube layout verified')
        batch.lab_events.create!(description: 'AMP plate layout verified')
      end

      it 'does not include a link to verify AMP plates' do
        found_amp_plate_verify_option = false

        batch_submenu_presenter.each_option do |option|
          found_amp_plate_verify_option = true if option == amp_plate_verify_option
        end

        expect(found_amp_plate_verify_option).to be false
      end

      it 'does not include a link to verify tubes' do
        found_tube_verify_option = false

        batch_submenu_presenter.each_option do |option|
          found_tube_verify_option = true if option == tube_verify_option
        end

        expect(found_tube_verify_option).to be false
      end
    end
  end
end
