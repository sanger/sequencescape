class ::Endpoints::QcableCreators < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:user,   :json => 'user')
    belongs_to(:lot,  :json => 'lot')
    has_many(:qcables,  :json => 'qcables', :to=>'qcables')
  end

end
