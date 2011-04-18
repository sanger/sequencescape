class Endpoints::Submissions < Core::Endpoint::Base
  model do

  end

  instance do
    has_many(
      :requests, :json => 'requests', :to => 'requests',
      :include => [ :study, :project, :source_asset, :target_asset ]
    )
    belongs_to(:project, :json => 'project')
    belongs_to(:study,   :json => 'study')

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
