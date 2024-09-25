# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'support:remove_duplicate_asset_links', type: :task do
  let(:load_tasks) { Rails.application.load_tasks }
  let(:task_reenable) { Rake::Task[self.class.top_level_description].reenable }
  let(:task_invoke) { Rake::Task[self.class.top_level_description].invoke(csv_file_path) }
  let(:csv_file_path) { Rails.root.join('tmp/deleted_asset_links.csv').to_s }
  let(:links) { create_list(:asset_link, 5) }
  let(:duplicate_links) do
    links.map do |link|
      duplicate = AssetLink.new(ancestor: link.ancestor, descendant: link.descendant, created_at: 1.day.ago)
      duplicate.save!(validate: false)
      duplicate
    end
  end

  before do
    load_tasks # Load tasks directly in the test to avoid intermittent CI failures
    task_reenable # Allows the task to be invoked again
    links
    duplicate_links
  end

  after { File.delete(csv_file_path) if File.exist?(csv_file_path) }

  it 'removes all duplicate links except the most recently created ones' do
    expect(AssetLink.count).to eq(links.size + duplicate_links.size)
    task_invoke
    expect(AssetLink.count).to eq(links.size) # most recent links should be kept
    expect(AssetLink.exists?(links.first.id)).to be true
    expect(AssetLink.exists?(duplicate_links.first.id)).to be false
  end

  it 'exports the removed duplicates to a CSV file' do
    task_invoke
    expect(File.exist?(csv_file_path)).to be true
    csv = CSV.read(csv_file_path)
    expect(csv.size).to eq(duplicate_links.size + 1) # With header.
    expect(csv.first).to eq(AssetLink.column_names)
    (1..duplicate_links.size).each do |i|
      expected_row = duplicate_links[i - 1].attributes.values.map { |value| value&.to_s }
      expect(csv[i]).to eq(expected_row)
    end
  end
end
