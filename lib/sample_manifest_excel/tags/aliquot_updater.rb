# frozen_string_literal: true

module SampleManifestExcel
  module Tags
    ##
    # AliquotUpdater
    # TODO: Add specific tests
    module AliquotUpdater
      extend ActiveSupport::Concern

      ##
      # ClassMethods
      module ClassMethods
        def set_tag_name(name) # rubocop:disable Naming/AccessorMethodName
          define_method :tag_name do
            name
          end
        end
      end

      def update(attributes = {})
        return unless valid?

        tag =
          if value.present?
            attributes[:tag_group]
              .tags
              .find_or_create_by(oligo: value) { |t| t.map_id = attributes[:tag_group].tags.count + 1 }
          end
        aliquots.each { |aliquot| aliquot.assign_attributes(tag_name => tag) }
      end
    end
  end
end
