# Controls API V1 {::Core::Endpoint::Base endpoints} for Tag2LayoutTemplates
class ::Endpoints::Tag2LayoutTemplates < ::Core::Endpoint::Base
  model do
  end

  instance do
    action(:create) do |request, _|
      ActiveRecord::Base.transaction do
        request.create!(::Io::Tag2Layout.map_parameters_to_attributes(request.json).reverse_merge(user: request.user))
      end
    end
  end
end
