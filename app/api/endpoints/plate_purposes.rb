class ::Endpoints::PlatePurposes < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:child_plate_purposes, :json => 'children', :to => 'children')

    has_many(:plates, :json => 'plates', :to => 'plates') do
      action(:create) do |request, _|
        ActiveRecord::Base.transaction do
          # Look up the wells from the UUIDs passed, then remap the mapping.
          locations_to_uuids = request.json['plate']['wells']
          uuids              = Uuid.include_resource.lookup_many_uuids(locations_to_uuids.values)
          uuids_to_wells     = Hash[uuids.map { |uuid| [uuid.external_id, uuid.resource] }]
          locations_to_wells = Hash[locations_to_uuids.map { |location,uuid| [location, uuids_to_wells[uuid]] }]

          request.target.proxy_owner.create!(locations_to_wells).tap do |plate|
            request.target << plate
          end
        end
      end
      action_requires_authorisation(:create)
    end
  end
end
