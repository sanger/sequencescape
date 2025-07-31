# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'samples/index.html.erb' do
  include AuthenticatedSystem

  let(:user) { create(:user) }

  context 'when rendering the index view' do
    let(:current_user) { user }
    let(:samples) { create_list(:sample, 4) }
    let(:time) { DateTime.now.utc }
    let(:time2) { DateTime.now.utc + 5 }

    context 'when the user has withdrawn consent' do
      before do
        samples[0].update(
          consent_withdrawn: true,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time
        )

        samples[2].update(
          consent_withdrawn: true,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time2
        )

        list = Sample.where(id: samples.map(&:id)).order(created_at: :desc).page(1)
        assign(:samples, list)
      end

      it 'renders the withdrawn message for each sample' do
        regexp =
          Regexp.new(
            # rubocop:todo Layout/LineLength
            "Patient consent has been withdrawn for this sample.*by user.*#{current_user.login}.*at .*#{time.to_fs(:db)}.*",
            # rubocop:enable Layout/LineLength
            Regexp::MULTILINE
          )
        regexp2 =
          Regexp.new(
            # rubocop:todo Layout/LineLength
            "Patient consent has been withdrawn for this sample.*by user.*#{current_user.login}.*at .*#{time2.to_fs(:db)}.*",
            # rubocop:enable Layout/LineLength
            Regexp::MULTILINE
          )
        render
        expect(rendered).to match(regexp)
        expect(rendered).to match(regexp2)
      end
    end

    context 'when the user has no withdrawn consent' do
      before do
        samples[0].update(
          consent_withdrawn: false,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time
        )

        samples[2].update(
          consent_withdrawn: false,
          user_id_of_consent_withdrawn: current_user.id,
          date_of_consent_withdrawn: time2
        )

        list = Sample.where(id: samples.map(&:id)).order(created_at: :desc).page(1)
        assign(:samples, list)
      end

      it 'does not render the withdrawn message for each sample' do
        regexp =
          Regexp.new(
            # rubocop:todo Layout/LineLength
            "Patient consent has been withdrawn for this sample.*by user.*#{current_user.login}.*at .*#{time.to_fs(:db)}.*",
            # rubocop:enable Layout/LineLength
            Regexp::MULTILINE
          )
        regexp2 =
          Regexp.new(
            # rubocop:todo Layout/LineLength
            "Patient consent has been withdrawn for this sample.*by user.*#{current_user.login}.*at .*#{time2.to_fs(:db)}.*",
            # rubocop:enable Layout/LineLength
            Regexp::MULTILINE
          )
        render
        expect(rendered).not_to match(regexp)
        expect(rendered).not_to match(regexp2)
      end
    end
  end
end
