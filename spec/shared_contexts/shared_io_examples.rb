# frozen_string_literal: true

shared_examples 'an IO object' do
  let(:rendered_json) { described_class.to_hash(subject) }
  it 'renders json' do
    expect(rendered_json).to include_json(expected_json)
  end
end
