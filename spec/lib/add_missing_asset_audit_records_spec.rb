# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'asset_audit:add_missing_records' do
  let(:file_path) { 'testfile.csv' }
  let(:run_rake_task) do
    Rake::Task['asset_audit:add_missing_records'].reenable
    Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
  end

  before do
    Rake.application.rake_require 'tasks/add_missing_asset_audit_records'
    Rake::Task.define_task(:environment)
    allow(File).to receive(:exist?).and_return(true) # Stub default value
  end

  context 'when file path is not provided' do
    let(:run_rake_task) do
      Rake::Task['asset_audit:add_missing_records'].reenable
      Rake.application.invoke_task('asset_audit:add_missing_records[nil]')
    end

    it 'outputs an error message and exits' do
      expect { run_rake_task }.to output('Please provide a valid file path').to_stdout
    end
  end

  context 'when file does not exist' do
    # let (:file_path) { 'testfile.csv' }
    # let(:run_rake_task) do
    #   Rake::Task['asset_audit:add_missing_records'].reenable
    #   Rake.application.invoke_task('asset_audit:add_missing_records[testfile.csv]')
    # end

    before { allow(File).to receive(:exist?).with(file_path).and_return(false) }

    it 'outputs an error message and exits' do
      expect { run_rake_task }.to output('Please provide a valid file path').to_stdout
    end
  end

  context 'when CSV read fails' do
    # let (:file_path) { 'testfile.csv' }
    # let(:run_rake_task) do
    #   Rake::Task['asset_audit:add_missing_records'].reenable
    #   Rake.application.invoke_task('asset_audit:add_missing_records[testfile.csv]')
    # end
    it 'outputs an error message and exits' do
      allow(CSV).to receive(:read).and_raise(StandardError, 'Test error')

      expect { run_rake_task }.to output(/Failed to read CSV file: Test error/).to_stdout
    end
  end

  context 'when file exists' do
    # let (:file_path) { 'testfile.csv' }
    # let(:run_rake_task) do
    #   Rake::Task['asset_audit:add_missing_records'].reenable
    #   Rake.application.invoke_task('asset_audit:add_missing_records[testfile.csv]')
    # end
    let(:csv_content) { <<~CSV }
        barcode,message,created_by,created_at
        SQPD-1,Destroying location,User1,2021-01-01 12:00:00
        SQPD-2,Destroying labware,User2,2021-01-02 12:00:00
      CSV

    before do
      allow(CSV).to receive(:read).with(file_path, headers: true).and_return(CSV.parse(csv_content, headers: true))
    end

    it 'adds missing asset audit records' do
      plate1 = create(:plate, barcode: 'SQPD-1')
      plate2 = create(:plate, barcode: 'SQPD-2')

      expected_output =
        Regexp.new(
          "Adding missing asset audit records...\\n" \
            "Record for asset_id #{plate1.id} successfully inserted.\\n" \
            "Record for asset_id #{plate2.id} successfully inserted.\\n"
        )
      expect { run_rake_task }.to output(expected_output).to_stdout
      expect(AssetAudit.count).to eq(2)
      expect(
        AssetAudit.where(
          asset_id: plate1.id,
          key: 'destroy_location',
          message: 'Process \'Destroying location\' performed on instrument Destroying instrument'
        ).count
      ).to eq(1)
      expect(
        AssetAudit.where(
          asset_id: plate2.id,
          key: 'destroy_labware',
          message: 'Process \'Destroying labware\' performed on instrument Destroying instrument'
        ).count
      ).to eq(1)
    end

    it 'skips records with invalid records' do
      plate = create(:plate, barcode: 'SQPD-1')

      expect { run_rake_task }.to output(/Adding missing asset audit records.../).to_stdout

      expect(AssetAudit.count).to eq(1)
      expect(
        AssetAudit.where(
          asset_id: plate.id,
          key: 'destroy_location',
          message: 'Process \'Destroying location\' performed on instrument Destroying instrument'
        ).count
      ).to eq(1)
    end

    it 'handles errors when inserting records' do
      plate = create(:plate, barcode: 'SQPD-1')
      allow(AssetAudit).to receive(:create!).and_raise(ActiveRecord::ActiveRecordError, 'Test error')

      expect { run_rake_task }.to output(/Error inserting record for asset_id #{plate.id}: Test error/).to_stdout

      expect(AssetAudit.count).to eq(0)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
