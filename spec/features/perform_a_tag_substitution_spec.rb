# frozen_string_literal: true

require 'rails_helper'

feature 'Perform a tag substitution' do
  let(:sample_a) { create :sample }
  let(:sample_b) { create :sample }
  let(:library_tube_a) { create :library_tube }
  let(:library_tube_b) { create :library_tube }
  let(:mx_library_tube) { create :multiplexed_library_tube }
  let(:library_type) { create :library_type }
  let(:sample_a_orig_tag) { create :tag }
  let(:sample_a_orig_tag2) { create :tag }

  let(:sample_b_orig_tag) { create :tag }
  let(:sample_b_orig_tag2) { create :tag }

  let!(:lane) { create :lane }

  let(:user) { create :user }

  background do
    create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_tube_a, receptacle: library_tube_a
    create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_tube_b, receptacle: library_tube_b
    create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_tube_a, receptacle: mx_library_tube
    create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_tube_b, receptacle: mx_library_tube
    create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_tube_a, receptacle: lane
    create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_tube_b, receptacle: lane
  end

  scenario 'Performing a tag swap' do
    login_user user
    visit asset_path(lane)
    click_link 'perform tag substitution'
    expect(page).to have_content(lane.name)
    fill_in('Ticket', with: '12345')
    select('Incorrect tags selected in Sequencescape.', from: 'Reason')
    find('td', text: "#{sample_a.id}: #{sample_a.sanger_sample_id}")
      .ancestor('tr')
      .fill_in('tag_substitution[substitutions][][substitute_tag_id]', with: sample_b_orig_tag.id)
    find('td', text: "#{sample_b.id}: #{sample_a.sanger_sample_id}")
      .ancestor('tr')
      .fill_in('tag_substitution[substitutions][][substitute_tag_id]', with: sample_a_orig_tag.id)
    click_button 'Substitute Tags'
    expect(page).to have_content "Asset #{lane.display_name}"
    expect(page).to have_content 'Your substitution was performed.'
    find('td', text: sample_a.name).sibling('td', text: "(#{sample_b_orig_tag.oligo})")
    find('td', text: sample_a.name).sibling('td', text: "(#{sample_a_orig_tag2.oligo})")
    find('td', text: sample_b.name).sibling('td', text: "(#{sample_a_orig_tag.oligo})")
    find('td', text: sample_b.name).sibling('td', text: "(#{sample_b_orig_tag2.oligo})")
  end
end
