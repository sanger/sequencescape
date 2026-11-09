# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe 'Gel QC' do
  let(:user) { create(:user, :with_role, role_name: 'slf_gel', login: 'john') }
  let(:stock_purpose) { create(:stock_plate_purpose, name: 'Stock Plate') }
  let(:stock) { legacy_plate(Plate, stock_purpose, '1220000123724') }

  def legacy_plate(klass, purpose, barcode)
    klass.create!(
      sanger_barcode: Barcode.build_sanger_code39(machine_barcode: barcode, format: 'DN'),
      plate_purpose: purpose,
      name: barcode
    )
  end

  def add_dilutions(direct: true)
    working_purpose = create(:working_dilution_plate_purpose, name: 'Working Dilution')
    working = legacy_plate(WorkingDilutionPlate, working_purpose, '6250000123818')
    gel = add_gel
    stock.children << working
    (direct ? stock : working).children << gel
  end

  def add_gel
    purpose = create(:plate_purpose, name: 'Gel Dilution', target_type: 'GelDilutionPlate', prefix: 'GD')
    legacy_plate(GelDilutionPlate, purpose, '1930000123708')
  end

  def add_samples
    stock.wells.each_with_index do |well, index|
      well.aliquots.clear
      well.aliquots.create!(sample: Sample.create!(name: "Sample_#{index}_on_1220000123724"))
    end
  end

  def lookup_stock
    fill_in 'barcode', with: 'DN123'
    click_button 'Update gel values'
    expect(page).to have_text('Plate DN123H')
  end

  def update_gel(score)
    select score, from: 'A1'
    click_button 'Update gel values'
    expect(page).to have_text('Gel results for plate updated')
    expect(page).to have_current_path(gels_path)
  end

  def expect_gel_score(score)
    stored_score = score == 'No Band' ? 'Band Not Visible' : score
    expect(stock.find_well_by_name('A1').well_attribute.reload.gel_pass).to eq(stored_score)
  end

  def visit_gel_index
    visit gels_path
    expect(page).to have_current_path(gels_path)
    expect(page).to have_text('Find gel plate')
  end

  before do
    login_user user
    # Cucumber uses bare Wells and row-major map ids, not factory wells with default QC values.
    %w[A1 A2 A3].each do |position|
      Well.create!(plate: stock, map: stock.maps.find_by!(description: position))
    end
    visit_gel_index
    travel_to Time.zone.parse('14-Feb-2011 23:00:00+01:00')
  end

  it 'displays the index for a gel dilution linked through a working dilution' do
    add_dilutions(direct: false)
    visit gels_path
    expect(page).to have_current_path(gels_path)
    expect(page).to have_text('Find gel plate')
  end

  it 'displays an unscored gel dilution linked directly to the stock plate' do
    add_dilutions
    visit gels_path
    expect(page).to have_current_path(gels_path)
    expect(page).to have_text('Find gel plate')
    expect(page).to have_text('DN123H')
    expect(page).to have_no_text('Rescore')
  end

  it 'does not display a gel dilution without parents' do
    add_gel
    visit gels_path
    expect(page).to have_current_path(gels_path)
    expect(page).to have_text('Find gel plate')
    expect(page).to have_no_text('DN123H')
  end

  it 'offers rescore after scoring and records gel analysed events on the plate and every well' do
    add_dilutions
    add_samples
    visit gels_path
    expect(page).to have_current_path(gels_path)
    expect(page).to have_text('Find gel plate')
    expect(page).to have_text('DN123H')
    expect(page).to have_no_text('Rescore')
    click_link 'Score'
    click_button 'Update gel values'
    visit gels_path
    expect(page).to have_text('Rescore')
    [stock, *stock.wells].each do |asset|
      expect(asset.events.find_by(family: 'gel_analysed')).to be_present
    end
    click_link 'DN123H'
    click_link 'Event history'
    events = find_by_id('events').all('tr').map { |row| row.all('th, td').map(&:text) }
    columns = ['Message', 'Content', 'Created by'].map { |header| events.first.index(header) }
    expect(events.map { |row| row.values_at(*columns) }).to eq(
      [['Message', 'Content', 'Created by'], ['Gel Analysed', '2011-02-14', 'john']]
    )
  end

  it 'includes the gel score and analysed date for every well in the generated study report' do
    add_dilutions
    add_samples
    study = create(:study, name: 'Test study', state: 'pending')
    study.activate!
    RequestFactory.create_assets_requests(stock.wells, study)
    visit gels_path
    click_link 'Score'
    click_button 'Update gel values'
    report = StudyReport.create!(study:)
    report.perform
    # The source table selects these three columns from the wider report.
    rows = CSV.parse(report.reload.report.file.read, headers: true)
    expect(rows.map { |row| row.values_at('Gel', 'Well', 'Gel QC date') }).to eq(
      [%w[OK A1 2011-02-14], %w[OK A2 2011-02-14], %w[OK A3 2011-02-14]]
    )
  end

  it 'looks up a plate with complete sample names and saves No Band' do
    add_samples
    lookup_stock
    update_gel('No Band')
    expect_gel_score('No Band')
  end

  it 'sets Degraded on a well' do
    add_samples
    lookup_stock
    update_gel('Degraded')
    expect_gel_score('Degraded')
  end

  it 'looks up a plate with no samples without offering No Band' do
    lookup_stock
    expect(page).to have_no_text('No Band')
    expect(page).to have_no_select('A1')
  end

  ['Water', 'water', 'WATER', 'Blank', '', 'empty'].each do |sample_name|
    it "hides well A2 with SNP sample name #{sample_name.inspect} while permitting other wells to be scored" do
      add_samples
      well = stock.find_well_by_name('A2')
      well.aliquots.clear
      sample = Sample.new(name: sample_name)
      sample.save!(validate: false)
      well.aliquots.create!(sample:)
      lookup_stock
      expect(page).to have_no_text('Well A2')
      expect(page).to have_no_select('A2')
      update_gel('No Band')
      expect_gel_score('No Band')
    end
  end

  it 'hides a manifest well with an empty supplier sample name while permitting other wells to be scored' do
    add_samples
    well = stock.find_well_by_name('A2')
    well.aliquots.clear
    well.aliquots.create!(
      sample: Sample.create!(name: 'Sample_A2_on_plate_1220000123724', empty_supplier_sample_name: true)
    )
    lookup_stock
    expect(page).to have_no_text('Well A2')
    expect(page).to have_no_select('A2')
    update_gel('No Band')
    expect_gel_score('No Band')
  end
end
