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

    action(:create) do |request,response|
      response.status(201)
      build_transfer(request, &request.target.method(:create!))
    end
    bind_action(:create, :as => 'preview', :to => 'preview') do |_,request,response|
      response.status(200)
      build_transfer(request, &request.target.method(:preview!))
    end
  end
end
