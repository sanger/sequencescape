# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'labware/retention_instruction.html.erb' do
  include AuthenticatedSystem
  include RetentionInstructionHelper
  let(:user) { create :user }

  before do
    assign(:asset, asset)
    assign(:retention_instruction_options, retention_instruction_option_for_select)
    render
  end

  context 'when rendering an existing retention instruction' do
    let(:current_user) { user }
    let(:asset) { create :plate_with_3_wells, retention_instruction: :destroy_after_2_years }

    it 'displays the retention instruction' do
      expect(rendered).to match(/Retention Instruction/)
    end

    it 'displays the retention instruction value' do
      expect(rendered).to match(/Destroy after 2 years/)
    end

    it 'displays a form to update the retention instruction' do
      expect(rendered).to have_css('form')
      expect(rendered).to have_css('select')
    end

    it 'displays a submit button' do
      expect(rendered).to have_css('input[type="submit"]')
    end
  end

end