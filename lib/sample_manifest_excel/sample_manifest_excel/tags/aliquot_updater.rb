module SampleManifestExcel
  module Tags
    # TODO: Add specific tests
    module AliquotUpdater
      extend ActiveSupport::Concern

      module ClassMethods
        def set_tag_name(name)
          define_method :tag_name do
            name
          end
        end
      end

      def update(attributes = {})
        if valid?
          tag = if value.present?
            attributes[:tag_group].tags.find_or_create_by(oligo: value) do |t|
              t.map_id = attributes[:tag_group].tags.count + 1
            end
          end
          attributes[:aliquot].send("#{tag_name}=", tag)
        end
      end
    end
  end
end
