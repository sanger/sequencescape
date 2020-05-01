module Api
  module V2
    # This class adds the plate purpose to the context so PlateResource can use it to
    # generate the new instance of the Plate
    class PlateProcessor < JSONAPI::Processor
      def create_resource
        @params.dig(:data, :attributes).tap do |attrs|
          # We permit wells content as it is not permitted by default
          attrs[:wells_content]&.permit!

          inject_study(attrs[:wells_content], attrs[:study_uuid]) if attrs[:wells_content] && attrs[:study_uuid]

          # We set up context to store plate_purpose_uuid
          @context[:plate_purpose_uuid] = attrs[:plate_purpose_uuid] if attrs[:plate_purpose_uuid]
        end
        ActiveRecord::Base.transaction do
          super
        end
      end

      def inject_study(wells_content, study_uuid)
        [wells_content.values].flatten.each do |content|
          content[:study_uuid] = study_uuid
        end
      end
    end
  end
end
