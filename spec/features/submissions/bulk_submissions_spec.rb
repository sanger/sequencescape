# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'Bulk submission', js: false do
  let(:user) { create :admin, login: 'user' }
  let(:study) { create :study, name: 'abc123_study' }

  def process_submission(filename, encoding = nil)
    attach_file('bulk_submission_spreadsheet', Rails.root.join('features', 'submission', 'csv', filename))
    select(encoding, from: 'Encoding') if encoding
    click_button 'Create Bulk submission'
  end

  background do
    login_user user
    create :project, name: 'Test project'
    create :asset_group, name: 'assetgroup123', study: study, asset_count: 2
    visit bulk_submissions_path
    expect(page).to have_content('Bulk Submission New')
  end

  shared_examples 'bulk submission file upload' do
    it 'allows file upload' do
      process_submission(file_name, encoding)
      Array[expected_content].flatten.each do |content|
        expect(page).to have_content content
      end
      expect(Submission.count).to eq(submission_count) if submission_count
    end
  end

  context 'with default encoding' do
    let(:encoding) { nil }

    context 'with one submission' do
      let(:submission_count) { 1 }

      context 'Uploading a valid file with 1 submission' do
        let(:file_name) { '1_valid_rows.csv' }
        let(:expected_content) { ['Bulk submission successfully made', 'Your submissions:'] }
        it_behaves_like 'bulk submission file upload'
      end
      # context "Uploading a valid file with bait library specified should set the bait library name" do
      #   # Given I have a well called "testing123"
      #   # And the sample in the last well is registered under the study "abc123_study"
      #   When I upload a file with 2 valid SC submissions
      #   let(:expected_content) { "Your submissions:" }
      #    And there should be an order with the bait library name set to "Bait library 1"
      #    And there should be an order with the bait library name set to "Bait library 2"
      #    And the last submission should have a priority of 1
      #   it_behaves_like 'bulk submission file upload'
      # end
    end

    context 'Uploading a valid file with gb expected specified should set the gb expected' do
        let(:file_name) { '2_valid_rows.csv' }
        let(:submission_count) { 2 }
        let(:expected_content) { 'Your submissions:' }

        it 'allows file upload' do
          process_submission(file_name)
          Array[expected_content].flatten.each do |content|
            expect(page).to have_content content
          end
          expect(Order.last.request_options['gigabases_expected']).to eq('1.35')
        end
    end

    context 'with no submissions' do
      let(:submission_count) { 0 }

      context 'Uploading a valid file with 1 submission but a deprecated template' do
        let(:file_name) { '1_deprecated_rows.csv' }
        let(:expected_content) { "Template: 'Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing' is deprecated and no longer in use." }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 1 submissions' do
        let(:file_name) { '1_invalid_rows.csv' }
        let(:expected_content) { 'No user specified for testing124' }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 2 submissions' do
        let(:file_name) { '2_invalid_rows.csv' }
        let(:expected_content) { 'There was a problem on row(s)' }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading a file with conflicting orders' do
        let(:file_name) { 'with_conflicting_submissions.csv' }
        let(:expected_content) { 'Column, read length, should be identical for all requests in asset group assetgroup123' }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 2 submissions' do
        let(:file_name) { '1_valid_1_invalid.csv' }
        let(:expected_content) { 'There was a problem on row(s)' }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an empty file' do
        let(:file_name) { 'no_rows.csv' }
        let(:expected_content) { 'The supplied file was empty' }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading a file without a (valid) header row' do
        let(:file_name) { 'bad_header.csv' }
        let(:expected_content) { 'The supplied file does not contain a valid header row' }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 1 submissions Windows-1252 encoded characters' do
        let(:file_name) { 'invalid_cp1252_rows.csv' }
        let(:expected_content) { 'abc123 — study' }
        it_behaves_like 'bulk submission file upload'
      end

      context 'Leaving the file field blank' do
        it 'produces an error' do
          click_button 'Create Bulk submission'
          expect(page).to have_content("can't be blank")
        end
      end
    end
  end

  context 'Uploading an invalid file with 1 submissions utf-8 encoded characters' do
    let(:file_name) { 'invalid_utf8_rows.csv' }
    let(:encoding) { 'UTF-8' }
    let(:expected_content) { 'abc123 — study' }
    let(:submission_count) { 0 }
    it_behaves_like 'bulk submission file upload'
  end
end
