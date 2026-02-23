# frozen_string_literal: true

require 'spec_helper'
require './app/helpers/application_helper'

describe ApplicationHelper do
  describe '#favicon' do
    subject(:favicon) { helper.favicon }

    it 'returns the favicon path for the production environment' do
      allow(Rails).to receive(:env).and_return('production')
      expect(favicon).to eq('favicon.ico')
    end

    it 'returns the favicon path for the training environment' do
      allow(Rails).to receive(:env).and_return('training')
      expect(favicon).to eq('favicon-training.ico')
    end

    it 'returns the favicon path for the staging environment' do
      allow(Rails).to receive(:env).and_return('staging')
      expect(favicon).to eq('favicon-staging.ico')
    end

    it 'returns the favicon path for the development environment' do
      allow(Rails).to receive(:env).and_return('development')
      expect(favicon).to eq('favicon-development.ico')
    end

    it 'returns the favicon path for an unknown environment' do
      allow(Rails).to receive(:env).and_return('unknown')
      expect(favicon).to eq('favicon-development.ico')
    end
  end

  describe '#apple_icon' do
    subject(:apple_icon) { helper.apple_icon }

    it 'returns the apple icon path for the production environment' do
      allow(Rails).to receive(:env).and_return('production')
      expect(apple_icon).to eq('apple-icon.png')
    end

    it 'returns the apple icon path for the training environment' do
      allow(Rails).to receive(:env).and_return('training')
      expect(apple_icon).to eq('apple-icon-training.png')
    end

    it 'returns the apple icon path for the staging environment' do
      allow(Rails).to receive(:env).and_return('staging')
      expect(apple_icon).to eq('apple-icon-staging.png')
    end

    it 'returns the apple icon path for the development environment' do
      allow(Rails).to receive(:env).and_return('development')
      expect(apple_icon).to eq('apple-icon-development.png')
    end

    it 'returns the apple icon path for an unknown environment' do
      allow(Rails).to receive(:env).and_return('unknown')
      expect(apple_icon).to eq('apple-icon-development.png')
    end
  end

  describe '#render_parsed_json' do
    subject(:returned_html) { render_parsed_json(json) }

    context 'with a string' do
      let(:json) { 'String' }

      it 'returns the string', :aggregate_failures do
        expect(returned_html).to eq(json)
      end
    end

    context 'with a number' do
      let(:json) { 1 }

      it 'returns the string' do
        expect(returned_html).to eq('1')
      end
    end

    context 'with a hash (representing a js object)' do
      let(:json) { { key_a: 'a', key_b: 'b' } }

      it 'returns a descriptive list' do
        expect(returned_html).to eq('<dl><dt>key_a</dt><dd>a</dd><dt>key_b</dt><dd>b</dd></dl>')
      end
    end

    context 'with an array (representing a js object)' do
      let(:json) { %w[a b] }

      it 'returns an unordered list' do
        expect(returned_html).to eq('<ul><li>a</li><li>b</li></ul>')
      end
    end

    context 'with a mix of content' do
      let(:json) { { 'Key a' => 'String', 'Key b' => %w[a b], 'Key c' => { 'nexted' => 'object' } } }

      it 'works recursively' do
        expect(returned_html).to eq(
          '<dl><dt>Key a</dt><dd>String</dd>' \
          '<dt>Key b</dt><dd><ul><li>a</li><li>b</li></ul></dd>' \
          '<dt>Key c</dt><dd><dl><dt>nexted</dt><dd>object</dd></dl></dd></dl>'
        )
      end
    end
  end

  describe '#render_message' do
    let(:html) { helper.render_message(messages) }

    context 'when messages is a Hash' do
      let(:messages) { { 'Description 1' => ['Item 1', 'Item 2'], 'Description 2' => 'Single Item' } }

      it 'renders each key as a div and each value as a list' do
        expect(html).to include('<div>Description 1</div>')
          .and include('<li>Item 1</li>')
          .and include('<li>Item 2</li>')
          .and include('<div>Description 2</div>')
          .and include('<li>Single Item</li>')
      end
    end

    context 'when messages is an Array with multiple items' do
      let(:messages) { ['Error 1', 'Error 2'] }

      it 'renders the messages as a list' do
        expect(html).to include('<ul>')
          .and include('<li>Error 1</li>')
          .and include('<li>Error 2</li>')
      end
    end

    context 'when messages is an Array with one item' do
      let(:messages) { ['Only one error'] }

      it 'renders the single message as a div' do
        expect(html).to include('<div>Only one error</div>')
      end
    end

    context 'when messages is a String' do
      let(:messages) { 'Just a string' }

      it 'renders the string as a div' do
        expect(html).to include('<div>Just a string</div>')
      end
    end
  end

  describe '#render_in_list' do
    it 'renders an array of messages as a list' do
      html = helper.render_in_list(%w[foo bar])
      expect(html).to include('<ul>')
        .and include('<li>foo</li>')
        .and include('<li>bar</li>')
    end
  end
end
