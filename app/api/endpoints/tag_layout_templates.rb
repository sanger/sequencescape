class ::Endpoints::TagLayoutTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    action(:create) do |request, _|
      ActiveRecord::Base.transaction do
        plate_from_request(request).owner = user_from_request(request)
        request.create!(::Io::TagLayout.map_parameters_to_attributes(request.json).reverse_merge(:user => request.user))
      end
    end

    def user_from_request(request)
      User.find(Uuid.find_id(request.json["transfer"]["user"]))
    end

    def plate_from_request(request)
      plate_from_uuid(request.json["transfer"]["plate"])
    end

    def plate_from_uuid(uuid)
      Plate.find(Uuid.find_id(uuid))
    end

  end
end
