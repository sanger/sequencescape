class Endpoints::Submissions < Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    has_many(
      :requests, :json => 'requests', :to => 'requests',
      :include => [ :source_asset, :target_asset ]
    )

    action(:update, :to => :standard_update!, :if => :building?)

    bind_action(:create, :as => :submit, :to => 'submit', :if => :building?) do |request, response|
      ActiveRecord::Base.transaction do
        request.target.tap do |submission|
          submission.built!
          response.status(200)    # OK
        end
      end
    end
  end
end
