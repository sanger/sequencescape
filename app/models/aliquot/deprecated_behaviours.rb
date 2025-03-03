# frozen_string_literal: true

# The following module is included where we have deprecated behaviours that rely on sample or request.
module Aliquot::DeprecatedBehaviours
  module Request
    def tag_number
      tag.try(:map_id) || ''
    end
    deprecate :tag_number, deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

    # Logged calls from: app/controllers/batches_controller.rb:259, _app_views_batches_print_labels_html_erb

    # tags and tag have been moved to the appropriate assets.
    # I don't think that they are used anywhere else apart
    # from the batch xml and can therefore probably be removed.
    # ---
    # Nope, they are used all over the place.
    def tag
      target_asset.primary_aliquot.try(:tag)
    end
    deprecate :tag, deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

    # Logged calls from: app/models/aliquot/deprecated_behaviours.rb

    delegate :tags, to: :asset
    deprecate :tags, deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')
  end
end
