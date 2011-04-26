class ::Endpoints::SampleManifests < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:study, :json => "study")
    belongs_to(:supplier, :json => "supplier")

    action(:update) do |request, response|
      ActiveRecord::Base.transaction do
        request.target.tap do |manifest|
          manifest.update_attributes!(request.attributes(request.target), request.user)
        end
      end
    end
  end
end
