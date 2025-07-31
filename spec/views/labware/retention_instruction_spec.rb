# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'labware/retention_instruction.html.erb' do
  include AuthenticatedSystem
  include RetentionInstructionHelper

  let(:user) { create(:user) }

  shared_examples 'displaying retention instruction' do
    it 'displays the retention instruction' do
      expect(rendered).to match(/Retention Instruction/)
    end

    it 'displays the retention instruction value' do
      expect(rendered).to match(/Destroy after 2 years/)
    end

    it 'displays a form to update the retention instruction' do
      expect(rendered).to have_css('form')
      expect(rendered).to have_select(
        'labware[retention_instruction]',
        options: retention_instruction_option_for_select.map(&:first)
      )
    end

    it 'displays a submit button' do
      expect(rendered).to have_button('Update')
    end
  end

  before do
    assign(:asset, asset)
    assign(:retention_instruction_options, retention_instruction_option_for_select)
    render
  end

  context 'when rendering an existing retention instruction - plate' do
    let(:current_user) { user }
    let(:asset) { create(:plate_with_3_wells, retention_instruction: :destroy_after_2_years) }

    it_behaves_like 'displaying retention instruction'
  end

  context 'when rendering an existing retention instruction - tube' do
    let(:current_user) { user }
    let(:asset) { create(:tube, retention_instruction: :destroy_after_2_years) }

    it_behaves_like 'displaying retention instruction'
  end
end
