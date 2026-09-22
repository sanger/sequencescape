# frozen_string_literal: true

RSpec.describe Api::V2::Concerns::ApiKeyAuthenticatable do
  # Dummy controller to include the concern for testing
  controller(ApplicationController) do
    include Api::V2::Concerns::ApiKeyAuthenticatable # rubocop:disable RSpec/DescribedClass
  end

  describe '#permissive_route' do
    context 'when permissive param includes :get and request method is GET' do
      before do
        allow(controller.request).to receive_messages(path_parameters: { permissive: [:get] }, method: 'GET')
      end

      it 'returns true' do
        expect(controller.send(:permissive_route)).to be true
      end
    end

    context 'when permissive param includes :get but request method is not GET' do
      before do
        allow(controller.request).to receive_messages(path_parameters: { permissive: [:get] }, method: 'POST')
      end

      it 'returns false' do
        expect(controller.send(:permissive_route)).to be false
      end
    end

    context 'when permissive param is not present' do
      before do
        allow(controller.request).to receive_messages(path_parameters: {}, method: 'GET')
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

    context 'when using permissive route behaviour' do
      before { Flipper.enable(:y25_442_make_api_key_mandatory) }

      context 'when the route is permissive and y25_441_remove_permissive_routes is disabled' do
        before do
          allow(controller).to receive(:permissive_route).and_return(true)
          Flipper.disable(:y25_441_remove_permissive_routes)
        end

        it 'does not render unauthorized' do
          controller.send(:authenticate_with_api_key)

          expect(controller).not_to have_received(:render_unauthorized)
        end
      end

      context 'when the route is permissive but y25_441_remove_permissive_routes is enabled' do
        before do
          allow(controller).to receive(:permissive_route).and_return(true)
          Flipper.enable(:y25_441_remove_permissive_routes)
        end

        it 'renders unauthorized' do
          controller.send(:authenticate_with_api_key)

          expect(controller).to have_received(:render_unauthorized)
        end
      end

      context 'when the route is not permissive and y25_441_remove_permissive_routes is disabled' do
        before do
          allow(controller).to receive(:permissive_route).and_return(false)
          Flipper.disable(:y25_441_remove_permissive_routes)
        end

        it 'renders unauthorized' do
          controller.send(:authenticate_with_api_key)

          expect(controller).to have_received(:render_unauthorized)
        end
      end

      context 'when the route is not permissive and y25_441_remove_permissive_routes is enabled' do
        before do
          allow(controller).to receive(:permissive_route).and_return(false)
          Flipper.enable(:y25_441_remove_permissive_routes)
        end

        it 'renders unauthorized' do
          controller.send(:authenticate_with_api_key)

          expect(controller).to have_received(:render_unauthorized)
        end
      end
    end

    context 'when an invalid API key is provided' do
      before do
        allow(controller.request).to receive_messages(env: { 'HTTP_X_SEQUENCESCAPE_CLIENT_ID' => 'bad-key' })
        Flipper.enable(:y25_442_make_api_key_mandatory)
      end

      context 'when the route is permissive and y25_441_remove_permissive_routes is disabled' do
        before do
          allow(controller).to receive(:permissive_route).and_return(true)
          Flipper.disable(:y25_441_remove_permissive_routes)
        end

        it 'does not render unauthorized' do
          controller.send(:authenticate_with_api_key)

          expect(controller).not_to have_received(:render_unauthorized)
        end
      end

      context 'when the route is permissive but y25_441_remove_permissive_routes is enabled' do
        before do
          allow(controller).to receive(:permissive_route).and_return(true)
          Flipper.enable(:y25_441_remove_permissive_routes)
        end

        it 'renders unauthorized' do
          controller.send(:authenticate_with_api_key)

          expect(controller).to have_received(:render_unauthorized)
        end
      end

      context 'when the route is not permissive' do
        before do
          allow(controller).to receive(:permissive_route).and_return(false)
          Flipper.disable(:y25_441_remove_permissive_routes)
        end

        it 'renders unauthorized' do
          controller.send(:authenticate_with_api_key)

          expect(controller).to have_received(:render_unauthorized)
        end
      end
    end
  end
end
