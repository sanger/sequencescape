# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'asset_audit:add_missing_records', type: :task do
  before do
    Rake.application.rake_require 'tasks/add_missing_asset_audit_records'
    Rake::Task.define_task(:environment)
  end

  context 'when an invalid file path is given' do
    let(:run_rake_task) do
      Rake::Task['asset_audit:add_missing_records'].reenable
      Rake.application.invoke_task('asset_audit:add_missing_records[nil]')
    end

    it 'outputs an error message and returns' do
      expect { run_rake_task }.to raise_error(RuntimeError, /Please provide a valid file path/)
    end
  end

  describe 'invalid csv file' do
    context 'when csv has a bad format' do
      let(:file_path) { 'spec/data/asset_audits/bad_format.csv' }
      let(:run_rake_task) do
        Rake::Task['asset_audit:add_missing_records'].reenable
        Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
      end

      it 'outputs an error message and return' do
        expect { run_rake_task }.to raise_error(RuntimeError, /Failed to read CSV file/)
      end
    end

    context 'when csv columns are mising' do
      let(:file_path) { 'spec/data/asset_audits/missing_column.csv' }
      let(:run_rake_task) do
        Rake::Task['asset_audit:add_missing_records'].reenable
        Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
      end

      it 'outputs an error message and return' do
        expect { run_rake_task }.to raise_error(RuntimeError, 'Failed to read CSV file: Missing columns.')
      end
    end

    context 'when csv with no header given' do
      let(:file_path) { 'spec/data/asset_audits/missing_header.csv' }
      let(:run_rake_task) do
        Rake::Task['asset_audit:add_missing_records'].reenable
        Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
      end

      it 'outputs an error message and return' do
        expect { run_rake_task }.to raise_error(/Failed to read CSV file: Invalid number of header columns./)
      end
    end
  end

  describe 'valid csv file' do
    context 'when asset with barcode is not found' do
      let(:file_path) { 'spec/data/asset_audits/valid_data.csv' }
      let(:run_rake_task) do
        Rake::Task['asset_audit:add_missing_records'].reenable
        Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
      end

      it 'does not add records if there is any invalid data' do
        create(:plate, barcode: 'SQPD-1')

        expect { run_rake_task }.to raise_error(RuntimeError, 'Asset with barcode SQPD-2 not found.')
      end
    end

    context 'when message column is invalid' do
      let(:file_path) { 'spec/data/asset_audits/invalid_message.csv' }
      let(:run_rake_task) do
        Rake::Task['asset_audit:add_missing_records'].reenable
        Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
      end

      it 'does not add records if there is any invalid data' do
        create(:plate, barcode: 'SQPD-1')

        expect { run_rake_task }.to raise_error(RuntimeError, 'Invalid message for asset with barcode SQPD-1.')
      end
    end

    context 'when all data is good' do
      let(:file_path) { 'spec/data/asset_audits/valid_data.csv' }
      let(:run_rake_task) do
        Rake::Task['asset_audit:add_missing_records'].reenable
        Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
      end

      it 'adds missing asset audit records' do
        plate1 = create(:plate, barcode: 'SQPD-1')
        plate2 = create(:plate, barcode: 'SQPD-2')

        expect { run_rake_task }.to output(/All records successfully inserted./).to_stdout

        expect(
          AssetAudit.where(
            asset_id: plate1.id,
            key: 'destroy_location',
            message: "Process 'Destroying location' performed on instrument Destroying instrument"
          )
        ).to exist

        expect(
          AssetAudit.where(
            asset_id: plate2.id,
            key: 'destroy_labware',
            message: "Process 'Destroying labware' performed on instrument Destroying instrument"
          )
        ).to exist
      end
    end

    context 'when there is a failed transaction' do
      let(:file_path) { 'spec/data/asset_audits/valid_data.csv' }
      let(:run_rake_task) do
        Rake::Task['asset_audit:add_missing_records'].reenable
        Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
      end

      it 'rolls back transaction when there is an error in inserting records' do
        create(:plate, barcode: 'SQPD-1')
        create(:plate, barcode: 'SQPD-2')
        allow(AssetAudit).to receive(:create!).and_raise(ActiveRecord::ActiveRecordError, 'Test error')

        expect { run_rake_task }.to output(/Failed to insert records: Test error/).to_stdout
      end
    end
  end
end
