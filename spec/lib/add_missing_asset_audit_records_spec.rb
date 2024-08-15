# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'asset_audit:add_missing_records', type: :task do
  let(:run_rake_task) do
    Rake::Task['asset_audit:add_missing_records'].reenable
    Rake.application.invoke_task('asset_audit:add_missing_records')
  end

  before do
    Rake.application.rake_require 'tasks/add_missing_asset_audit_records'
    Rake::Task.define_task(:environment)
  end

  context 'when file path is not provided' do
    let(:file_path) { nil }

    it 'outputs an error message and exits' do
      expect { run_rake_task }.to output('Please provide a valid file path').to_stdout
    end
  end

  context 'when file does not exist' do
    let(:file_path) { 'non_existent_file.csv' }

    before { allow(File).to receive(:exist?).with(file_path).and_return(false) }

    it 'outputs an error message and exits' do
      expect { run_rake_task }.to output('Please provide a valid file path').to_stdout
    end
  end

  context 'when file exists' do
    let(:file_path) { 'spec/lib/asset_audit_records.csv' }
    let(:csv_content) { <<~CSV }
        barcode,message,created_by,created_at
        SQPD-1,Destroying location,User1,2021-01-01 12:00:00
        SQPD-2,Destroying labware,User2,2021-01-02 12:00:00
      CSV

    before do
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(CSV).to receive(:read).with(file_path, headers: true).and_return(CSV.parse(csv_content, headers: true))
    end

    it 'adds missing asset audit records' do
      plate1 = create(:plate, barcode: 'SQPD-1')
      plate2 = create(:plate, barcode: 'SQPD-2')

      expect { run_rake_task }.to output(
        /
          Adding\ missing\ asset\ audit\ records...\n
          Record\ for\ asset_id\ #{plate1.id}\ successfully\ inserted.\n
          Record\ for\ asset_id\ #{plate2.id}\ successfully\ inserted.\n
        /x
      ).to_stdout

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
      create(:plate, barcode: 'SQPD-1')

      expect { run_rake_task }.to output(/Adding missing asset audit records.../).to_stdout

      expect(AssetAudit.count).to eq(1)
      expect(
        AssetAudit.where(
          asset_id: plate1.id,
          key: 'destroy_location',
          message: 'Process \'Destroying location\' performed on instrument Destroying instrument'
        ).count
      ).to eq(1)
    end

    it 'handles errors when inserting records' do
      create(:plate, barcode: 'SQPD-1')
      allow(AssetAudit).to receive(:create!).and_raise(ActiveRecord::ActiveRecordError, 'Test error')

      expect { run_rake_task }.to output(/Error inserting record for asset_id #{labware1.id}: Test error/).to_stdout

      expect(AssetAudit.count).to eq(0)
    end
  end
end
