# frozen_string_literal: true

require 'rails_helper'

feature 'Create a QC report' do
  let(:user)                { create(:admin) }
  let!(:study)              { create(:study) }
  let!(:product_criteria)   { create(:product_criteria) }
  let(:plate_purposes)      { create_list :plate_purpose, 3 }
  let(:plate_purpose_names) { plate_purposes.map(&:name) }

  before(:each) do
    create(:plate_purpose)
    create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: plate_purposes[0]))
    create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: plate_purposes[1]))
    create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: plate_purposes[2]))
  end

  scenario 'create a new report' do
    login_user user
    visit qc_reports_path
    within('#new_report') do
      select(study.name, from: 'Study')
      select(product_criteria.product.display_name, from: 'Product')
      plate_purpose_names.each do |plate_purpose|
        select(plate_purpose, from: 'Plate purpose')
      end
    end
    click_button('Create report')
    expect(QcReport.first.plate_purposes & plate_purpose_names).to eq(plate_purpose_names)
  end
end
