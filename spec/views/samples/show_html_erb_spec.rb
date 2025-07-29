# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'samples/show.html.erb' do
  include AuthenticatedSystem

  let(:user) { create(:user) }

  context 'when rendering a sample' do
    let(:current_user) { user }
    let(:sample) { create(:sample) }
    let(:time) { DateTime.now.utc }

    context 'when the user has withdrawn consent' do
      before do
        sample.update(
          consent_withdrawn: true,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time
        )
        assign(:sample, sample) # sets @widget = Widget.new in the view template
      end

      it 'renders the withdrawn message' do
        regexp =
          Regexp.new(
            # rubocop:todo Layout/LineLength
            "Patient consent has been withdrawn for this sample.*by user.*#{current_user.login}.*at .*#{time.to_fs(:db)}.*",
            # rubocop:enable Layout/LineLength
            Regexp::MULTILINE
          )
        render
        expect(rendered).to match(regexp)
      end
    end

    context 'when the user has no withdraw consent' do
      before do
        sample.update(
          consent_withdrawn: false,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time
        )
        assign(:sample, sample) # sets @widget = Widget.new in the view template
      end

      it 'does not render the withdrawn message' do
        regexp =
          Regexp.new(
            # rubocop:todo Layout/LineLength
            "Patient consent has been withdrawn for this sample.*by user.*#{current_user.login}.*at .*#{time.to_fs(:db)}.*",
            # rubocop:enable Layout/LineLength
            Regexp::MULTILINE
          )
        render
        expect(rendered).not_to match(regexp)
      end
    end
  end
end
