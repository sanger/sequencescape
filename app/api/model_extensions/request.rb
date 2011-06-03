module ModelExtensions::Request
  def self.included(base)
    base.class_eval do
      named_scope :include_source_asset, :include => {
        :asset => [
          :uuid_object,
          :barcode_prefix,
          :scanned_into_lab_event,
          { :aliquots => [ :sample, :tag ] }
        ]
      }
      named_scope :include_target_asset, :include => {
        :target_asset => [
          :uuid_object,
          :barcode_prefix,
          { :aliquots => [ :sample, :tag ] }
        ]
      }

      named_scope :include_study, :include => { :study => :uuid_object }
      named_scope :include_project, :include => { :project => :uuid_object }
      named_scope :include_request_type, :include => :request_type
      named_scope :include_submission, :include => { :submission => :uuid_object }

      belongs_to :target_asset, :class_name => "Asset"
      accepts_nested_attributes_for :target_asset, :update_only => true

      belongs_to :asset
      accepts_nested_attributes_for :asset, :update_only => true
    end
  end
end
