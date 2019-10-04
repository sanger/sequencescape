# Included in {Request}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Request
  def self.included(base)
    base.class_eval do
      scope :include_source_asset, -> {
        includes(
          asset: [
            :uuid_object,
            :barcodes,
            :scanned_into_lab_event,
            { aliquots: %i[sample tag] }
          ]
        )
      }
      scope :include_target_asset, -> {
        includes(
          target_asset: [
            :uuid_object,
            :barcodes,
            { aliquots: %i[sample tag] }
          ]
        )
      }

      scope :include_study, -> { includes(study: :uuid_object) }
      scope :include_project, -> { includes(project: :uuid_object) }
      scope :include_request_type, -> { includes(:request_type) }
      scope :include_submission, -> { includes(submission: :uuid_object) }
    end
  end
end
