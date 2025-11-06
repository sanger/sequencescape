# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Presenters::BatchSubmenuPresenter, type: :model do
  subject{ described_class.new(current_user, batch) }

  context 'in the Ultima sequencing pipeline' do
    let(:current_user) { create(:user) }
    let(:batch) { create(:ultima_sequencing_batch) }

    it 'includes a link to print plate amp labels' do
      plate_amp_labels_option = { label: 'Print plate amp labels', url: "/batches/#{batch.id}/print_plate_amp_labels" }
      found_plate_amp_labels_option = false

      subject.each_option do |option|
        puts option
        expect(option.is_a?(Hash)).to be true
        expect(option).to have_key(:label)
        expect(option).to have_key(:url)
        found_plate_amp_labels_option = true if option == plate_amp_labels_option
      end

      expect(found_plate_amp_labels_option).to be true
    end
  end
end
