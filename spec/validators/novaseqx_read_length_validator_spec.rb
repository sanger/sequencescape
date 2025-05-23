# frozen_string_literal: true
RSpec.describe RequestType::Validator, type: :model do
  describe 'NovaSeqX read length validator' do
    let(:request_type) { create(:nova_seq_x_sequencing_request_type) }
    let(:validator) { request_type.request_type_validators.find_by(request_option: 'read_length') }

    it 'has the correct valid options' do
      expect(validator.valid_options.to_a).to contain_exactly(50, 100, 150)
    end

    it 'includes 50 as a valid option' do
      expect(validator.include?(50)).to be true
    end

    it 'sets 50 as the default value' do
      expect(validator.default).to eq(50)
    end
  end
end
