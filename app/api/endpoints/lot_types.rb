class ::Endpoints::LotTypes < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:lots, :json=>'lots', :to=>'lots') do
      action(:create) do |request,_|
        ActiveRecord::Base.transaction do
          request.target.proxy_owner.create!(request.attributes)
        end
      end
    end
  end

end
