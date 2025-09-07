# frozen_string_literal: true

RSpec.describe Api::V2::Concerns::ApiKeyAuthenticatable do
  # Dummy controller to include the concern for testing
  controller(ApplicationController) do
    include Api::V2::Concerns::ApiKeyAuthenticatable # rubocop:disable RSpec/DescribedClass
  end

  describe '#permissive_route' do
    context 'when permissive param is present and request is GET' do
      before do
        allow(controller.request).to receive_messages(path_parameters: { permissive: true }, get?: true)
      end

      it 'returns true' do
        expect(controller.send(:permissive_route)).to be true
      end
    end

    context 'when permissive param is present but request is not GET' do
      before do
        allow(controller.request).to receive_messages(path_parameters: { permissive: true }, get?: false)
      end

      it 'returns false' do
        expect(controller.send(:permissive_route)).to be false
      end
    end

    context 'when permissive param is not present' do
      before do
        allow(controller.request).to receive_messages(path_parameters: {}, get?: true)
      end

      it 'returns false' do
        expect(controller.send(:permissive_route)).to be false
      end
    end
  end

  describe '#authenticate_with_api_key' do
    before do
      allow(controller.request).to receive_messages(env: {}, path_parameters: {}, get?: true)
      allow(controller).to receive(:render_unauthorized)
    end

    context 'when feature flag is enabled' do
      before do
        Flipper.enable(:y25_442_make_api_key_mandatory)
      end

      it 'renders unauthorized when no API key is provided' do
        controller.send(:authenticate_with_api_key)

        expect(controller).to have_received(:render_unauthorized)
      end
    end

    context 'when feature flag is disabled' do
      before do
        Flipper.disable(:y25_442_make_api_key_mandatory)
      end

      it 'does not render unauthorized when no API key is provided' do
        controller.send(:authenticate_with_api_key)

        expect(controller).not_to have_received(:render_unauthorized)
      end
    end
  end
end
