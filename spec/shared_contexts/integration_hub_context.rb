# frozen_string_literal: true
RSpec.shared_context 'when request from Integration Hub' do
  let!(:integration_hub) { create(:api_application, name: 'Integration Hub') }

  around do |example|
    Current.api_application = integration_hub
    example.run
  ensure
    Current.reset
  end
end
