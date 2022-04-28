# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

RSpec.describe BootstrapHelper do
  describe '#bs_select' do
    it 'handles no additional parameters' do
      expect(
        helper.bs_select(:obj, :att, %w[opt])
      ).to eq '<select class="custom-select" name="obj[att]" id="obj_att"><option value="opt">opt</option></select>'
    end

    it 'handles an options hash' do
      expect(
        helper.bs_select(:obj, :att, %w[opt], {})
      ).to eq '<select class="custom-select" name="obj[att]" id="obj_att"><option value="opt">opt</option></select>'
    end

    it 'handles an html and options hash' do
      expect(
        helper.bs_select(:obj, :att, %w[opt], {}, {})
      ).to eq '<select class="custom-select" name="obj[att]" id="obj_att"><option value="opt">opt</option></select>'
    end

    it 'handles a custom class' do
      expect(helper.bs_select(:obj, :att, %w[opt], {}, { class: 'other' })).to eq(
        '<select class="other custom-select" name="obj[att]" id="obj_att"><option value="opt">opt</option></select>'
      )
    end
  end
end
