# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/submission_serializer')

RSpec.describe 'Bulk submission from tubes' do
  let(:user) { create(:user, :with_role, role_name: 'internal', login: 'user', first_name: 'John', last_name: 'Doe') }
  let(:study) { create(:study, name: 'abc123_study', state: 'pending') }

  around do |example|
    original_authentication = configatron.authentication
    example.run
  ensure
    configatron.authentication = original_authentication
  end

  def create_sample_tube_group(name, count)
    tubes = (1..count).map do |index|
      create(:sample_tube, name: "#{name}, sample tube #{index}",
                           sample_attributes: { name: "#{name} sample #{index}".gsub(/\s+/, '_').downcase })
    end
    create(:asset_group, name: name, study: study, assets: tubes.map(&:receptacle))
  end

  def upload_tube_submission
    attach_file(
      'bulk_submission_spreadsheet',
      Rails.root.join('spec/data/submission/bulk_submission/1_tube_submission.csv')
    )
    click_button 'Create Bulk submission'
  end

  def visit_bulk_submission_form
    visit new_bulk_submission_path
    expect(page).to have_text('Bulk Submission New')
  end

  before do
    login_user(user)
    configatron.authentication = 'local'

    # Cucumber loads this catalogue/product from 0000_products.rb. The
    # serializer alone cannot construct the catalogue's selection behaviour.
    ProductCatalogue.construct!(name: 'Generic', selection_behaviour: 'SingleProduct', products: { nil => 'Generic' })
    # The CSV names the Standard library type supplied by Cucumber's seeds.
    create(:library_type_standard)
    request_type = create(:library_creation_request_type)
    SubmissionSerializer.construct!(
      name: 'Example tube template',
      submission_class_name: 'LinearSubmission',
      product_catalogue: 'Generic',
      submission_parameters: { info_differential: 5, request_types: [request_type.key], order_role: 'ILB PATH' }
    )

    user.grant_administrator
    study.activate!
    create(:project, name: 'Test project')
    create_sample_tube_group('assetgroup123', 5)
    SampleTube.order(:id).each_with_index do |tube, index|
      barcode = SBCF::SangerBarcode.new(prefix: 'NT', number: index + 1).human_barcode
      Barcode.find_by(barcode:)&.update!(barcode: "XX#{index + 1}")
      tube.primary_barcode.update!(barcode:)
    end

    visit_bulk_submission_form
  end

  it 'uploads one submission containing exactly the two tubes specified by the CSV' do
    upload_tube_submission

    expect(page).to have_text('Your bulk submission has been processed.')
    assets = Submission.last.orders.flat_map(&:assets)
    expect(assets.size).to eq(2)
    expect(assets.map(&:human_barcode)).to include('NT1O', 'NT2P')
  end

  it 'rejects an asset-group name already used for different tubes' do
    create_sample_tube_group('novel_asset_group', 2)

    upload_tube_submission

    expect(page).to have_no_text('Your bulk submission has been processed')
    expect(page).to have_text(
      "Asset Group 'novel_asset_group' contains different assets to those you specified. " \
      'You may be reusing an asset group name'
    )
  end
end
