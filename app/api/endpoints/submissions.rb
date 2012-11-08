class Endpoints::Submissions < Core::Endpoint::Base
  model do
    action(:create) do |request, _|
      attributes = ::Io::Submission.map_parameters_to_attributes(request.json)
      request.target.create!(attributes.merge(:user => request.user))
    end
  end

  instance do
    has_many(
      :requests, :json => 'requests', :to => 'requests',
      :include => [ :source_asset, :target_asset ]
    )

    action(:update, :to => :standard_update!, :if => :building?)

    bind_action(:create, :as => :submit, :to => 'submit', :if => :building?) do |_, request, response|
      ActiveRecord::Base.transaction do
        request.target.tap do |submission|
          submission.built!
          response.status(200)    # OK
        end
      end
    end
  end
end
