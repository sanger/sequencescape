# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'
require './app/helpers/application_helper'

describe ApplicationHelper do
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
      let(:json) do
        {
          'Key a' => 'String',
          'Key b' => %w[a b],
          'Key c' => {
            'nexted' => 'object'
          }
        }
      end

      it 'works recursively' do
        expect(returned_html).to eq(
          '<dl><dt>Key a</dt><dd>String</dd>'\
          '<dt>Key b</dt><dd><ul><li>a</li><li>b</li></ul></dd>'\
          '<dt>Key c</dt><dd><dl><dt>nexted</dt><dd>object</dd></dl></dd></dl>'
        )
      end
    end
  end
end
