# frozen_string_literal: true

# Checks a Schemas::Validator subclass. Needs `validator`, and a
# `valid_payload` and an `invalid_payload` for its schema.
shared_examples 'a schema validator' do
  let(:errors) { validator.validate(invalid_payload) }

  it 'returns no errors for a valid payload' do
    expect(validator.validate(valid_payload)).to eq([])
  end

  it 'returns errors for an invalid payload' do
    expect(errors).not_to be_empty
  end

  it 'returns each error as a JSON pointer and a detail' do
    expect(errors).to all(
      match(pointer: a_string_matching(%r{\A(?:/.*)?\z}),
            detail: a_string_matching(/\S/))
    )
  end
end
