class ::Endpoints::TagLayoutTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    action(:create) do |request, _|
      ActiveRecord::Base.transaction do
        request.create!(::Io::TagLayout.map_parameters_to_attributes(request.json).reverse_merge(:user => request.user))
      end
    end

  end
end
