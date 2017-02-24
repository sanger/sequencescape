# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class ::Io::AssetAudit < ::Core::Io::Base
  # This module adds the behaviour we require from the AssetAudit module.
  module ApiIoSupport
    def self.included(base)
      base.class_eval do
        # TODO: add any named scopes
        # TODO: add any associations
      end
    end

    def asset_uuid
      asset.try(:uuid)
    end

    def asset_uuid=(uuid)
      self.asset = Uuid.with_external_id(uuid).include_resource.map(&:resource).first
    end

    # TODO: add any methods
  end

  set_model_for_input(::AssetAudit)
  set_json_root(:asset_audit)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  # TODO: define the mapping from the model attributes to the JSON attributes
  #
  # The rules are relatively straight forward with each line looking like '<attibute> <access> <json>', and blank lines or
  # those starting with '#' being considered comments and ignored.
  #
  # Here 'access' is either '=>' (for read only, indicating that the 'attribute' maps to the 'json'), or '<=' for write only (yes,
  # there are cases for this!) or '<=>' for read-write.
  #
  # The 'json' is the JSON attribute to generate in dot notation, i.e. 'parent.child' generates the JSON '{parent:{child:value}}'.
  #
  # The 'attribute' is the attribute to write, i.e. 'name' would be the 'name' attribute, and 'parent.name' would be the 'name'
  # attribute of whatever 'parent' is.

  define_attribute_and_json_mapping("
       message  <=> message
           key  <=> key
    created_by  <=> created_by
    asset_uuid  <=> asset
  witnessed_by  <=> witnessed_by
  ")
end
