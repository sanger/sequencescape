class ::Endpoints::Stamps < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:user, :json => 'user')
    belongs_to(:robot, :json => 'robot')
    belongs_to(:lot, :json=>'lot')
    has_many(:qcables,         :json => 'qcables', :to => 'qcables')
    has_many(:stamp_qcables,   :json => 'stamp_qcables', :to => 'stamp_qcables')
  end

end
