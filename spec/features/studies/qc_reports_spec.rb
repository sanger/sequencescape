# frozen_string_literal: true

require 'rails_helper'

feature 'Create a QC report' do
  let(:user)                { create(:admin) }
  let!(:study)              { create(:study) }
  let!(:product_criteria)   { create(:product_criteria) }
  let(:plate_purposes)      { ['ISC lib PCR-XP', 'Lib PCR-XP', 'PF Post Shear'] }

  before(:each) do
    plate_purposes.each do |plate_purpose|
      create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: PlatePurpose.find_by(name: plate_purpose)))
    end
  end

  scenario 'create a new report' do
    login_user user
    visit qc_reports_path
    within('#new_report') do
      select(study.name, from: 'Study')
      select(product_criteria.product.display_name, from: 'Product')
      plate_purposes.each do |plate_purpose|
        select(plate_purpose, from: 'Plate purpose')
      end
    end
    click_button('Create report')
    expect(QcReport.first.plate_purposes & plate_purposes).to eq(plate_purposes)
  end
end
