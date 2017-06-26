# frozen_string_literal: true
require 'rails_helper'

feature 'Create a QC report' do
  let(:user)                { create(:admin) }
  let!(:study)              { create(:study) }
  let!(:product_criteria)   { create(:product_criteria) }

  before(:each) do

    plate_isc = create(:plate, plate_purpose: PlatePurpose.find_by(name: 'ISC lib PCR-XP'))
    well = create :well, samples: [create(:study_sample, study: study).sample], plate: plate_isc, map: create(:map)
    well.aliquots.each { |a| a.update_attributes!(study: study) }

    plate_lib = create(:plate, plate_purpose: PlatePurpose.find_by(name: 'Lib PCR-XP'))
    well = create :well, samples: [create(:study_sample, study: study).sample], plate: plate_lib, map: create(:map)
    well.aliquots.each { |a| a.update_attributes!(study: study) }

    plate_pf = create(:plate, plate_purpose: PlatePurpose.find_by(name: 'PF Post Shear'))
    well = create :well, samples: [create(:study_sample, study: study).sample], plate: plate_pf, map: create(:map)
    well.aliquots.each { |a| a.update_attributes!(study: study) }
  end

  scenario 'create a new report' do
    login_user user
    visit qc_reports_path
    within('#new_report') do
      select(study.name, from: 'Study')
      select(product_criteria.product.display_name, from: 'Product')
      select('ISC lib PCR-XP', from: 'Plate purpose')
      select('Lib PCR-XP', from: 'Plate purpose')
      select('PF Post Shear', from: 'Plate purpose')
    end
    click_button('Create report')
    expect(QcReport.first.plate_purposes).to eq(['ISC lib PCR-XP', 'Lib PCR-XP', 'PF Post Shear'])
  end
end