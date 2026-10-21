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
        def fetch(_subject, _version)
          Schemas::Schema.new(text: '{}', type: :json_schema)
        end
      end.new
    end
    let(:schema_subject) { 'work-order' }
    let(:version) { 1 }

    it_behaves_like 'a schema source'
  end
end
