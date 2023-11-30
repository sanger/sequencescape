# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for BaitLibraryLayouts
class Endpoints::BaitLibraryLayouts < Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)

    # You can preview a bait library layout, which is effectively an unsaved version of the one
    # that will be created.
    bind_action(:create, as: 'preview', to: 'preview') do |_, request, response|
      request.target.preview!(request.attributes).tap { |_| response.status(200) }
    end
  end

  instance do
    belongs_to(:plate, json: 'plate')
    belongs_to(:user, json: 'user')
  end
end
