# frozen_string_literal: true

require 'spec_helper'
require './app/helpers/deprecation_helper'

describe DeprecationHelper do
  include FontawesomeHelper

  describe '#deprecate_section' do
    subject(:returned_html) { deprecate_section(**params) { '<p>Deprecated content</p>' } }

    context 'with only a message' do
      let(:params) { { message: 'This is old' } }
      let(:expected_icon) { 'fa-info-circle' }
      let(:expected_title) { 'Request for feedback' }
      let(:expected_style) { 'info' }

      it 'generates the expected warning', :aggregate_failures do
        expect(returned_html).to have_content('This is old')
        expect(returned_html).to have_content('Deprecated content')
        expect(returned_html).to include("fas #{expected_icon}")
        expect(returned_html).to include(expected_style)
      end
    end

    context 'with a message and a date 14 days in the future' do
      let(:params) { { message: 'This is old', date: 14.days.from_now.to_date } }
      let(:expected_icon) { 'fa-exclamation-circle' }
      let(:expected_title) { 'Scheduled for removal in 14 days' }
      let(:expected_style) { 'warning' }

      it 'generates the expected warning', :aggregate_failures do
        expect(returned_html).to have_content('This is old')
        expect(returned_html).to have_content('Deprecated content')
        expect(returned_html).to include("fas #{expected_icon}")
        expect(returned_html).to include(expected_style)
      end
    end

    context 'with a message and a date 2 days in the future' do
      let(:params) { { message: 'This is old', date: 2.days.from_now.to_date } }
      let(:expected_icon) { 'fa-exclamation-triangle' }
      let(:expected_title) { 'Scheduled for removal in 2 days' }
      let(:expected_style) { 'danger' }

      it 'generates the expected warning', :aggregate_failures do
        expect(returned_html).to have_content('This is old')
        expect(returned_html).to have_content('Deprecated content')
        expect(returned_html).to include("fas #{expected_icon}")
        expect(returned_html).to include(expected_style)
      end
    end

    context 'with a message and a date 2 days in the past' do
      let(:params) { { message: 'This is old', date: 2.days.ago.to_date } }
      let(:expected_icon) { 'fa-exclamation-triangle' }
      let(:expected_title) { 'Scheduled for removal in 2 days' }
      let(:expected_style) { 'danger' }

      it { is_expected.not_to have_content('Deprecated content') }
    end
  end
end
