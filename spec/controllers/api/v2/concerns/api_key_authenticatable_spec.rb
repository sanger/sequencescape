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
end
