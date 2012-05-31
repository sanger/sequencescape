class ::Endpoints::TransferTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    def build_transfer(request, &block)
      ActiveRecord::Base.transaction do
        # Here we have to map the JSON provided based on the transfer class we're going to build
        io_handler = ::Core::Io::Registry.instance.lookup_for_class(request.target.transfer_class)
        ActiveRecord::Base.transaction do
          yield(io_handler.map_parameters_to_attributes(request.json).reverse_merge(:user => request.user))
        end
      end
    end

    def user_from_request(request)
      User.find(Uuid.find_id(request.json["transfer"]["user"]))
    end

    def source_plate_from_request(request)
      plate_from_uuid(request.json["transfer"]["source"])
    end

    def destination_plate_from_request(request)
      plate_from_uuid(request.json["transfer"]["destination"])
    end

    def plate_from_uuid(uuid)
      Plate.find(Uuid.find_id(uuid))
    end

    action(:create) do |request,response|
      response.status(201)
      source_plate_from_request(request).owner = user_from_request(request)
      destination_plate_from_request(request).owner = user_from_request(request)
      build_transfer(request, &request.target.method(:create!))
    end
    bind_action(:create, :as => 'preview', :to => 'preview') do |request,response|
      response.status(200)
      build_transfer(request, &request.target.method(:preview!))
    end
  end
end
