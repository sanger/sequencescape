
class ::Endpoints::TransferTemplates < ::Core::Endpoint::Base
  model do
  end

  instance do
    def extract_parameters(request)
      # Here we have to map the JSON provided based on the transfer class we're going to build
      io_handler = ::Core::Io::Registry.instance.lookup_for_class(request.target.transfer_class)
      yield(io_handler.map_parameters_to_attributes(request.json).reverse_merge(user: request.user))
    end

    action(:create) do |request, response|
      response.status(201)
      ActiveRecord::Base.transaction do
        extract_parameters(request) do |parameters|
          request.target.create!(parameters)
        end
      end
    end
    bind_action(:create, as: 'preview', to: 'preview') do |_, request, response|
      response.status(200)
      extract_parameters(request) do |parameters|
        request.target.preview!(parameters)
      end
    end
  end
end
