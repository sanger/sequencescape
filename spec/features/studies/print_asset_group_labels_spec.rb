# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/6040471_truncate_sample_name_barcode.feature
describe 'Printing sample tube labels from an asset group' do
  let(:user) { create(:user, :with_role, role_name: 'manager', login: 'john') }
  let(:study) { create(:study, name: 'Test Study') }
  let(:asset_group) { AssetGroup.create!(name: 'Test asset group', study: study) }
  let(:sample_tube) do
    SampleTube.create!(name: tube_name, sanger_barcode: { number: '17', prefix: 'NT' }).tap do |tube|
      asset_group.assets << tube.receptacle
    end
  end
  let(:tube_name) { 'Test Sample Tube' }

  before do
    user.grant_manager(study)
    BarcodePrinter.create!(name: 'xyz', barcode_printer_type: BarcodePrinterType1DTube.first, active: true)
    stub_request(:post, LabelPrinter::PmbClient.print_job_url).with(headers: LabelPrinter::PmbClient.headers)
  end

  # Replaces the sample in the tube with one that has the given sanger_sample_id
  def give_tube_a_sample_with_sanger_sample_id(sanger_sample_id)
    sample_tube.receptacle.aliquots.clear
    sample_tube.receptacle.aliquots.create!(sample: Sample.create!(name: 'Sample_123456',
                                                                   sanger_sample_id: sanger_sample_id))
  end

  def print_labels_for_the_asset_group
    login_user(user)
    visit study_path(study)
    click_link 'Asset groups'
    click_link 'Print labels'
    select 'xyz', from: 'barcode_printer_list'
    click_button 'Print'
    expect(page).to have_text('Your 1 label(s) have been sent to printer xyz')
  end

  def expect_printed_label(first_line:)
    expect(
      a_request(:post, LabelPrinter::PmbClient.print_job_url).with do |request|
        label = JSON.parse(request.body).dig('print_job', 'labels').first
        label.slice('first_line', 'second_line', 'round_label_top_line', 'round_label_bottom_line') ==
          { 'first_line' => first_line, 'second_line' => '17', 'round_label_top_line' => 'NT',
            'round_label_bottom_line' => '17' }
      end
    ).to have_been_made.once
  end

  context 'when the tube has no name' do
    let(:tube_name) { '' }

    it 'prints a label with a blank first line' do
      sample_tube
      print_labels_for_the_asset_group
      expect_printed_label(first_line: '')
    end
  end

  it 'prints the tube name when the tube has no sample' do
    sample_tube
    print_labels_for_the_asset_group
    expect_printed_label(first_line: 'Test Sample Tube')
  end

  it 'prints the tube name when the sample has a blank sanger_sample_id' do
    give_tube_a_sample_with_sanger_sample_id('')
    print_labels_for_the_asset_group
    expect_printed_label(first_line: 'Test Sample Tube')
  end

  it 'prints a short sanger_sample_id in full' do
    give_tube_a_sample_with_sanger_sample_id('TW123456')
    print_labels_for_the_asset_group
    expect_printed_label(first_line: 'TW123456')
  end

  it 'prints the last 7 digits of a long sanger_sample_id' do
    give_tube_a_sample_with_sanger_sample_id('UK10K_Twins1234567')
    print_labels_for_the_asset_group
    expect_printed_label(first_line: '1234567')
  end
end
