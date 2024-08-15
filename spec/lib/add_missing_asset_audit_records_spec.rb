# frozen_string_literal: true

require 'rails_helper'
RSpec.describe 'asset_audit:add_missing_records', type: :task do
  let(:file_path) { File.join('spec', 'data', 'asset_audits', 'data.csv') }

  before do
    Rake.application.rake_require 'tasks/add_missing_asset_audit_records'
    Rake::Task.define_task(:environment)
    allow(File).to receive(:exist?).and_return(true) # Stub default value
  end

  context 'when file exists' do
    let(:run_rake_task) do
      Rake::Task['asset_audit:add_missing_records'].reenable
      Rake.application.invoke_task("asset_audit:add_missing_records[#{file_path}]")
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
    end
  end
end
