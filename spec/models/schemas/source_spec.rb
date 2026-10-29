# frozen_string_literal: true

require 'rails_helper'
require './spec/models/schemas/shared_examples/source'

RSpec.describe Schemas::Source do
  it 'leaves fetching to subclasses' do
    expect { described_class.new.fetch('work-order', 1) }
      .to raise_error(NotImplementedError)
  end

  context 'with a subclass that fetches a schema' do
    let(:source) do
      Class.new(described_class) do
        def fetch(_subject, version)
          version = 2 if version == :latest
          raise Schemas::Source::NotFound unless [1, 2].include?(version)

          Schemas::Schema.new(text: '{}', type: :json_schema,
                              version: version)
        end
      end.new
    end
    let(:schema_subject) { 'work-order' }
    let(:version) { 1 }
    let(:latest_version) { 2 }
    let(:missing_version) { 3 }

    it_behaves_like 'a schema source'
  end
end
