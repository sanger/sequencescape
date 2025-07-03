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
end
