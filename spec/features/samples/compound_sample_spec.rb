# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Compound sample page' do
  let(:user) { create(:user) }
  let(:compound) { create(:sample) }
  let(:components) { create_list(:sample, 2) }

  def component_panel
    find('h3', text: 'Component Samples').find(:xpath, '..')
  end

  before { login_user(user) }

  context 'when its component samples have tags' do
    let(:tag_group) { create(:tag_group, tag_count: 2) }
    let(:tags) { tag_group.tags.order(:map_id) }

    before do
      components.zip(tags).each do |component, tag|
        compound.joins_as_compound_sample
          .create!(component_sample: component, tag: tag)
      end
      visit sample_path(compound)
    end

    it 'shows the tag of each component sample' do
      rows = within(component_panel) { all('tbody tr').map(&:text) }
      expected = components.zip(tags).map do |component, tag|
        a_string_including(component.name, "#{tag.map_id} (#{tag.oligo})")
      end
      expect(rows).to match_array(expected)
    end

    it 'links the tag of each component sample to its tag group' do
      hrefs = within(component_panel) { all('a', text: 'Group').pluck(:href) }
      expect(hrefs).to eq([tag_group_path(tag_group)] * components.size)
    end
  end

  context 'when its component samples have no tags' do
    before do
      compound.update!(component_samples: components)
      visit sample_path(compound)
    end

    it 'shows no tag column' do
      panel = component_panel
      expect(panel).to have_no_css('th', text: 'Tag')
    end
  end
end
