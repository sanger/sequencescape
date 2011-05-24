class ::Endpoints::TransferTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    action(:create) do |request, _|
      ActiveRecord::Base.transaction do
        request.create!(::Io::Transfer.map_parameters_to_attributes(request.json).merge(:user => request.user))
      end
    end
  end
end
