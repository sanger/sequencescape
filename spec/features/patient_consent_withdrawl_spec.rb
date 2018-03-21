# frozen_string_literal: true

require 'rails_helper'

feature 'Sample#consent_withdrawn', js: false do
  # If a patient withdraws consent it should be clearly visible at multiple places.
  # These were moved from cucumber features. Some of these could be move elsewhere,
  # but the advantage of keeping them here is it does ensure the purpose is clear.
  # Essentially:
  # - If a patient withdraws consent we need to make sure everyone downstream knows
  # - We need to stop new orders being made.
  let(:user) { create :user, email: 'login@example.com' }
  let(:sample) { create :sample_with_gender, consent_withdrawn: consent_withdrawn }
  let(:study) { create :study }

  before do
    study.samples << sample
  end

  shared_examples 'an order' do
    scenario 'validates patient consent' do
      expect(order.valid?).to be(orders_valid)
      if orders_valid
        expect(order.errors).to_not be_present
      else
        expect(order.errors).to be_present
        expect(order.errors.full_messages).to(
          include("Samples in this submission have had patient consent withdrawn: #{sample.name}")
        )
      end
    end
  end

  shared_examples 'it reports information elsewhere' do
    scenario 'a user visits the sample.xml show page' do
      visit sample_path(sample, format: :xml)
      expect(page.find(:xpath, '//sample/consent_withdrawn').text).to eq xml_text
    end

    scenario 'we generate a warehouse message' do
      message = JSON.parse(sample.to_json)
      expect(message.dig('sample', 'consent_withdrawn')).to eq warehouse_value
    end

    context 'when batched' do
      let(:batch) { create :sequencing_batch, state: 'started' }
      let(:lane) { create :lane, samples: [sample] }

      before do
        batch.requests << create(:sequencing_request_with_assets, target_asset: lane)
      end

      scenario 'and a user visits the batch.xml show page' do
        visit batch_path(batch, format: :xml)
        expect(page.find('sample')['consent_withdrawn']).to eq xml_text
      end
    end

    context 'an order' do
      # Lifted straight from the feature test with minimal rspecification
      # and optimization
      let(:submission_template) { create :submission_template, request_type_ids_list: [[create(:request_type).id]] }
      let(:sample_tube) { create :sample_tube, sample: sample }
      let(:asset_group) { create :asset_group, assets: [sample_tube] }

      context 'defined by asset group' do
        let(:order) do
          submission_template.new_order(
            project: create(:project),
            study: study,
            asset_group: asset_group,
            user: user,
            request_options: {
              'fragment_size_required_from' => 300,
              'fragment_size_required_to' => 400,
              'read_length' => 108
            }
          )
        end
        it_behaves_like 'an order'
      end
      context 'defined by assets' do
        let(:order) do
          submission_template.new_order(
            project: create(:project),
            study: study,
            assets: [sample_tube],
            user: user,
            request_options: {
              'fragment_size_required_from' => 300,
              'fragment_size_required_to' => 400,
              'read_length' => 108
            }
          )
        end
        it_behaves_like 'an order'
      end
    end
  end

  context 'when true' do
    let(:consent_withdrawn) { true }
    let(:xml_text) { 'true' }
    let(:warehouse_value) { true }
    let(:orders_valid) { false }

    scenario 'a user visit the study sample page' do
      login_user user
      visit study_samples_path(study)
      within('.withdrawn') do
        expect(page).to have_content "#{sample.name} - Consent withdrawn"
      end
    end

    scenario 'a user visit the sample show page' do
      login_user user
      visit sample_path(sample)
      expect(page).to have_content 'Patient consent has been withdrawn for this sample.'
    end

    it_behaves_like 'it reports information elsewhere'
  end

  context 'when false' do
    let(:consent_withdrawn) { false }
    let(:xml_text) { 'false' }
    let(:warehouse_value) { false }
    let(:orders_valid) { true }

    scenario 'and a user visit the study show page' do
      login_user user
      visit study_samples_path(study)
      expect(page).to have_content sample.name
      expect(page).not_to have_content "#{sample.name} - Consent withdrawn"
      expect(page).not_to have_css('.withdrawn')
    end

    scenario 'and a user visit the sample show page' do
      login_user user
      visit sample_path(sample)
      expect(page).not_to have_content 'Patient consent has been withdrawn for this sample.'
    end

    it_behaves_like 'it reports information elsewhere'
  end
end
