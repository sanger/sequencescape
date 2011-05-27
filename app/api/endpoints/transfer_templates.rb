class ::Endpoints::TransferTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    action(:create) do |request, _|
      ActiveRecord::Base.transaction do
        # Here we have to map the JSON provided based on the transfer class we're going to create
        io_handler = ::Core::Io::Registry.instance.lookup_for_class(request.target.transfer_class)
        request.create!(io_handler.map_parameters_to_attributes(request.json).merge(:user => request.user))
      end
    end
  end
end
