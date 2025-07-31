# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'samples/edit.html.erb' do
  include AuthenticatedSystem
  include RSpecHtmlMatchers

  let(:user) { create(:user) }

  context 'when rendering the edit view' do
    let(:current_user) { user }
    let(:sample) { create(:sample) }
    let(:time) { DateTime.now }

    context 'when the sample has consent withdrawn' do
      before do
        sample.update(
          consent_withdrawn: true,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time
        )

        assign(:sample, sample)
      end

      it 'has the consent withdrawn selection selected' do
        render
        expect(rendered).to have_tag(
          'select',
          with: {
            name: 'sample[sample_metadata_attributes][consent_withdrawn]'
          },
          text: 'Yes'
        )
      end
    end

    context 'when the sample has no consent withdrawn' do
      before do
        sample.update(
          consent_withdrawn: false,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time
        )

        assign(:sample, sample)
      end

      it 'has the consent withdrawn selection unselected' do
        render
        expect(rendered).to have_tag(
          'select',
          with: {
            name: 'sample[sample_metadata_attributes][consent_withdrawn]'
          },
          text: 'No'
        )
      end
    end
  end
end
