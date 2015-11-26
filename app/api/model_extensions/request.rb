#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
module ModelExtensions::Request
  def self.included(base)
    base.class_eval do
      scope :include_source_asset, -> { includes(
        :asset => [
          :uuid_object,
          :barcode_prefix,
          :scanned_into_lab_event,
          { :aliquots => [ :sample, :tag ] }
        ]
      )}
      scope :include_target_asset, -> { includes(
        :target_asset => [
          :uuid_object,
          :barcode_prefix,
          { :aliquots => [ :sample, :tag ] }
        ]
      )}

      scope :include_study, -> { includes( :study => :uuid_object ) }
      scope :include_project, -> { includes( :project => :uuid_object ) }
      scope :include_request_type, -> { includes( :request_type ) }
      scope :include_submission, -> { includes( :submission => :uuid_object ) }

      # The assets on a request can be treated as a particular class when being used by certain pieces of code.  For instance,
      # QC might be performed on a source asset that is a well, in which case we'd like to load it as such.
      belongs_to :target_asset, :class_name => 'Aliquot::Receptacle', :inverse_of => :requests_as_target
      accepts_nested_attributes_for :target_asset, :update_only => true

      belongs_to :asset, :class_name => 'Aliquot::Receptacle', :inverse_of => :requests
      accepts_nested_attributes_for :asset, :update_only => true
      belongs_to :source_well, :class_name => 'Well', :foreign_key => :asset_id
    end
  end
end
