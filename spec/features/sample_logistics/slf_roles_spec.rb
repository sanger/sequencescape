# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SLF role permissions' do
  # Every row of the six Cucumber outlines is a separate, independently logged-in example.
  {
    'gel QC' => {
      path: :gels_path,
      text: 'Find gel plate',
      invalid: %w[follower internal lab lab_manager manager owner],
      valid: %w[slf_gel slf_manager administrator]
    },
    'plate templates' => {
      path: :plate_templates_path,
      text: 'New 96 Template',
      invalid: %w[follower internal lab lab_manager manager owner slf_gel],
      valid: %w[slf_manager administrator]
    },
    'sample logistics' => {
      path: :sample_logistics_path,
      text: 'Sample Management',
      invalid: %w[follower internal lab lab_manager manager owner],
      valid: %w[slf_manager administrator slf_gel]
    }
  }.each do |area, permissions|
    permissions[:invalid].each do |role|
      it "does not expose #{area} functions to #{role}" do
        login_user create(:user, :with_role, role_name: role, login: 'john')
        visit public_send(permissions[:path])
        # Invalid gel/logistics roles are allowed to redirect in the source feature.
        expect(page).to have_current_path(plate_templates_path) if area == 'plate templates'
        expect(page).to have_no_text(permissions[:text])
      end
    end

    permissions[:valid].each do |role|
      it "exposes #{area} functions to #{role}" do
        login_user create(:user, :with_role, role_name: role, login: 'john')
        visit public_send(permissions[:path])
        expect(page).to have_current_path(public_send(permissions[:path]))
        expect(page).to have_text(permissions[:text])
        if area == 'sample logistics'
          click_link 'Sample Management Lab View'
          expect(page).to have_text('Print plate barcodes')
        end
      end
    end
  end

  it 'shows only the permitted SLF homepage functions to an slf_gel user' do
    login_user create(:user, :with_role, role_name: 'slf_gel', login: 'john')
    visit sample_logistics_path
    expect(page).to have_current_path(sample_logistics_path)
    expect(page).to have_text('Sample Management')
    expect(page).to have_text('Gel')
    expect(page).to have_no_text('Suppliers')
    click_link 'Cherrypicking plate templates'
    expect(page).to have_no_text('New 96 Template')
  end
end
