# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AccessioningToolsHelper do
  # Stub icon helper (from font_awesome_helper / application helpers) to avoid dependency on asset pipeline
  before do
    allow(helper).to receive(:icon).with('fas', 'check', class: 'text-success')
      .and_return('<i class="check"></i>'.html_safe)
    allow(helper).to receive(:icon).with('fas', 'xmark', class: 'text-danger')
      .and_return('<i class="xmark"></i>'.html_safe)
  end

  describe '#action_checklist_item' do
    context 'when condition is true' do
      subject(:output) do
        helper.action_checklist_item(condition: true, good: 'This is working as expected', bad: 'Something went wrong')
      end

      it 'renders the good label' do
        expect(output).to include('This is working as expected')
      end

      it 'does not render the bad label' do
        expect(output).not_to include('Something went wrong')
      end

      it 'renders the success (check) icon' do
        expect(output).to include('check')
      end

      it 'does not render the danger (xmark) icon' do
        expect(output).not_to include('xmark')
      end
    end

    context 'when condition is false' do
      subject(:output) do
        helper.action_checklist_item(condition: false, good: 'This is working as expected', bad: 'Something went wrong')
      end

      it 'renders the bad label' do
        expect(output).to include('Something went wrong')
      end

      it 'does not render the good label' do
        expect(output).not_to include('This is working as expected')
      end

      it 'renders the danger (xmark) icon' do
        expect(output).to include('xmark')
      end

      it 'does not render the success (check) icon' do
        expect(output).not_to include('check')
      end
    end

    context 'with an action provided' do
      subject(:output) do
        helper.action_checklist_item(
          condition: true,
          good: 'This is working as expected',
          bad: 'Something went wrong',
          action: '<a href="/admin/settings">Change setting</a>'.html_safe
        )
      end

      it 'renders the action link' do
        expect(output).to include('<a href="/admin/settings">Change setting</a>')
      end

      it 'wraps the action in a muted span' do
        expect(output).to include('text-muted')
      end

      it 'renders the em dash separator before the action' do
        expect(output).to include(' — ')
      end
    end

    context 'without an action' do
      subject(:output) do
        helper.action_checklist_item(condition: true, good: 'This is working as expected', bad: 'Something went wrong')
      end

      it 'does not render a muted span' do
        expect(output).not_to include('text-muted')
      end

      it 'does not render the em dash' do
        expect(output).not_to include(' — ')
      end
    end

    context 'with an action and condition is false' do
      subject(:output) do
        helper.action_checklist_item(
          condition: false,
          good: 'This is working as expected',
          bad: 'Something went wrong',
          action: '<a href="/admin/settings">Change setting</a>'.html_safe
        )
      end

      it 'renders the bad label' do
        expect(output).to include('Something went wrong')
      end

      it 'renders the action link' do
        expect(output).to include('<a href="/admin/settings">Change setting</a>')
      end
    end
  end
end
