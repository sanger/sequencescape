# frozen_string_literal: true

# The following module is included where we have deprecated behaviours that rely on sample or request.
module Aliquot::DeprecatedBehaviours
  module Request
    def tag_number
      tag.try(:map_id) || ''
    end
    deprecate :tag_number
    # Logged calls from: app/controllers/batches_controller.rb:259, _app_views_batches_print_labels_html_erb

    # tags and tag have been moved to the appropriate assets.
    # I don't think that they are used anywhere else apart
    # from the batch xml and can therefore probably be removed.
    # ---
    # Nope, they are used all over the place.
    def tag
      target_asset.primary_aliquot.try(:tag)
    end
    deprecate :tag
    # Logged calls from: app/models/aliquot/deprecated_behaviours.rb

    delegate :tags, to: :asset
    deprecate :tags
    # ---

    def sample_name(default = nil)
      # return the name of the underlying samples
      # used mainly for compatibility with the old codebase
      # # default is used if no smaple
      # # block is used to aggregate the samples
      case
      when samples.size == 0 then default
      when samples.size == 1 then samples.first.name
      when block_given?      then yield(samples)
      else                        samples.map(&:name).join(' | ')
      end
    end
    deprecate :sample_name
    # Logged calls from: _app_views_workflows__set_characterisation_descriptors_html_erb
  end
end
