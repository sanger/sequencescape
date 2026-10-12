# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Compound sample pages' do
  let(:user) { create(:user) }
  let(:compound) { create(:sample) }
  let(:components) { create_list(:sample, 2) }
  let(:tag_group) { create(:tag_group, tag_count: 2) }
  let(:tags) { tag_group.tags.order(:map_id) }

  def component_panel
    find('h3', text: 'Component Samples').find(:xpath, '..')
  end

  def compound_panel
    find('h3', text: 'Compound Samples').find(:xpath, '..')
  end

  def link_with_tags
    components.zip(tags).each do |component, tag|
      compound.joins_as_compound_sample
        .create!(component_sample: component, tag: tag)
    end
  end

  before { login_user(user) }

  describe 'the compound sample page' do
    context 'when its component samples have tags' do
      before do
        link_with_tags
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
        hrefs =
          within(component_panel) { all('a', text: 'Group').pluck(:href) }
        expect(hrefs).to eq([tag_group_path(tag_group)] * components.size)
      end

      it 'does not list compound samples, as it is not a component' do
        component_panel # waits for the page
        expect(page).to have_no_css('h3', text: 'Compound Samples')
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

  describe 'a component sample page' do
    let(:component) { components.first }

    context 'when the component sample has a tag' do
      before do
        link_with_tags
        visit sample_path(component)
      end

      it 'links to its compound sample' do
        expect(compound_panel)
          .to have_link("Sample #{compound.id}", href: sample_path(compound))
      end

      it 'shows its tag in the compound sample' do
        tag = tags.first
        expect(compound_panel).to have_text("#{tag.map_id} (#{tag.oligo})")
      end
    end

    context 'when it is in more compound samples than fit on a page' do
      let(:per_page) { SamplesController::SAMPLES_PER_PAGE }
      let(:compounds) { create_list(:sample, per_page + 2) }

      before do
        compounds.each do |compound|
          compound.joins_as_compound_sample.create!(component_sample: component)
        end
      end

      it 'shows a page of compound samples' do
        visit sample_path(component)
        expect(compound_panel).to have_css('tbody tr', count: per_page)
      end

      it 'shows the rest on the next page' do
        visit sample_path(component, compound_page: 2)
        expect(compound_panel).to have_css('tbody tr', count: 2)
      end

      it 'pages them with their own parameter' do
        visit sample_path(component)
        next_page = sample_path(component, compound_page: 2)
        expect(compound_panel).to have_link('2', href: next_page)
      end
    end

    context 'when the component sample has no tag' do
      before do
        compound.update!(component_samples: components)
        visit sample_path(component)
      end

      it 'links to its compound sample' do
        expect(compound_panel)
          .to have_link("Sample #{compound.id}", href: sample_path(compound))
      end

      it 'shows no tag column' do
        panel = compound_panel
        expect(panel).to have_no_css('th', text: 'Tag')
      end
    end
  end
end
