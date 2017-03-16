# frozen_string_literal: true
require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/' do
  subject { '/api/1/' }

  context '#get' do
    let(:authorised_app) { create :api_application }

    let(:response_body) {
      %{{
        "revision": 2,
        "uuids": {
          "actions": {
            "lookup": "http://www.example.com/api/1/uuids/lookup",
            "bulk": "http://www.example.com/api/1/uuids/bulk"
          }
        },
        "searches": {
          "actions": {
            "read": "http://www.example.com/api/1/searches"
          }
        },

        "samples": {
          "actions": {
            "read": "http://www.example.com/api/1/samples"
          }
        },
        "sample_manifests": {
          "actions": {
          }
        },
        "suppliers": {
          "actions": {
            "read": "http://www.example.com/api/1/suppliers"
          }
        },

        "plate_purposes": {
          "actions": {
            "read": "http://www.example.com/api/1/plate_purposes",
            "create": "http://www.example.com/api/1/plate_purposes"
          }
        },
        "tube_purposes": {
          "actions": {
            "read": "http://www.example.com/api/1/tube/purposes",
            "create": "http://www.example.com/api/1/tube/purposes"
          }
        },
        "dilution_plate_purposes": {
          "actions": {
            "read": "http://www.example.com/api/1/dilution_plate_purposes",
            "create": "http://www.example.com/api/1/dilution_plate_purposes"
          }
        },
        "extraction_attributes": {
          "actions": {
            "read": "http://www.example.com/api/1/extraction_attributes"
          }
        },
        "assets": {
          "actions": {
            "read": "http://www.example.com/api/1/assets"
          }
        },
        "asset_audits": {
          "actions": {
            "read": "http://www.example.com/api/1/asset_audits",
            "create": "http://www.example.com/api/1/asset_audits"
          }
        },
        "asset_groups": {
          "actions": {
            "read": "http://www.example.com/api/1/asset_groups"
          }
        },
        "tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/tubes"
          }
        },
        "sample_tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/sample_tubes"
          }
        },
        "library_events": {
          "actions": {
            "read": "http://www.example.com/api/1/library_events",
            "create": "http://www.example.com/api/1/library_events"
          }
        },
        "library_tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/library_tubes"
          }
        },
        "lot_types": {
          "actions": {
            "read": "http://www.example.com/api/1/lot_types"
          }
        },
        "lots": {
          "actions": {
            "read": "http://www.example.com/api/1/lots"
          }
        },
        "multiplexed_library_tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/multiplexed_library_tubes"
          }
        },
        "plates": {
          "actions": {
            "read": "http://www.example.com/api/1/plates"
          }
        },
        "plate_conversions":
          {"actions": {
            "read": "http://www.example.com/api/1/plate_conversions",
            "create": "http://www.example.com/api/1/plate_conversions"
          }},
        "plate_templates":
          {"actions": {"read": "http://www.example.com/api/1/plate_templates"}},
        "batches": {
          "actions": {
            "read": "http://www.example.com/api/1/batches"
          }
        },
        "robots": {"actions": {"read": "http://www.example.com/api/1/robots"}},
        "stamps":{
          "actions":{
            "read":"http://www.example.com/api/1/stamps",
            "create":"http://www.example.com/api/1/stamps"
          }
        },
        "transfers": {
          "actions": {
            "read": "http://www.example.com/api/1/transfers",
            "create": "http://www.example.com/api/1/stamps"
          }
        },
        "wells": {
          "actions": {
            "read": "http://www.example.com/api/1/wells"
          }
        },
        "lanes": {
          "actions": {
            "read": "http://www.example.com/api/1/lanes"
          }
        },

        "request_types": {
          "actions": {
            "read": "http://www.example.com/api/1/request_types"
          }
        },
        "requests": {
          "actions": {
            "read": "http://www.example.com/api/1/requests"
          }
        },
        "multiplexed_library_creation_requests": {
          "actions": {
            "read": "http://www.example.com/api/1/multiplexed_library_creation_requests"
          }
        },
        "library_creation_requests": {
          "actions": {
            "read": "http://www.example.com/api/1/library_creation_requests"
          }
        },
        "sequencing_requests": {
          "actions": {
            "read": "http://www.example.com/api/1/sequencing_requests"
          }
        },

        "order_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/order_templates"
          }
        },
        "submissions": {
          "actions": {
            "read": "http://www.example.com/api/1/submissions",
            "create": "http://www.example.com/api/1/submissions"
          }
        },
        "submission_pools": {
          "actions": {
            "read": "http://www.example.com/api/1/submission_pools"
          }
        },
        "orders": {
          "actions": {
            "read": "http://www.example.com/api/1/orders"
          }
        },

        "studies": {
          "actions": {
            "read": "http://www.example.com/api/1/studies"
          }
        },
        "projects": {
          "actions": {
            "read": "http://www.example.com/api/1/projects"
          }
        },

        "pipelines": {
          "actions": {
            "read": "http://www.example.com/api/1/pipelines"
          }
        },
        "batches": {
          "actions": {
            "read": "http://www.example.com/api/1/batches"
          }
        },


        "transfers": {
          "actions": {
            "read": "http://www.example.com/api/1/transfers"
          }
        },
        "transfer_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/transfer_templates"
          }
        },

        "tag_layouts": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_layouts",
            "create": "http://www.example.com/api/1/tag_layouts"
          }
        },
        "tag2_layouts": {
          "actions": {
            "read": "http://www.example.com/api/1/tag2_layouts",
            "create": "http://www.example.com/api/1/tag2_layouts"
          }
        },

        "tag_groups": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_groups"
          }
        },
        "tag_layout_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_layout_templates"
          }
        },
        "tag2_layout_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/tag2_layout_templates"
          }
        },
        "plate_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/plate_creations",
            "create": "http://www.example.com/api/1/plate_creations"
          }
        },
        "tube_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/tube_creations",
            "create": "http://www.example.com/api/1/tube_creations"
          }
        },
        "state_changes": {
          "actions": {
            "read": "http://www.example.com/api/1/state_changes",
            "create": "http://www.example.com/api/1/state_changes"
          }
        },
        "bait_library_layouts": {
          "actions": {
            "read": "http://www.example.com/api/1/bait_library_layouts",
            "create": "http://www.example.com/api/1/bait_library_layouts",
            "preview": "http://www.example.com/api/1/bait_library_layouts/preview"
          }
        },

        "barcode_printers": {
          "actions": {
            "read": "http://www.example.com/api/1/barcode_printers"
          }
        },
        "users": {
          "actions": {
            "read": "http://www.example.com/api/1/users"
          }
        },
        "bulk_transfers": {
          "actions": {
            "read": "http://www.example.com/api/1/bulk_transfers",
            "create": "http://www.example.com/api/1/bulk_transfers"
          }
        },
        "comments": {
          "actions": {
          "read": "http://www.example.com/api/1/comments"
          }
        },
        "pooled_plate_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/pooled_plate_creations",
            "create": "http://www.example.com/api/1/pooled_plate_creations"
          }
        },
        "qc_decisions": {
          "actions": {
            "read": "http://www.example.com/api/1/qc_decisions",
            "create": "http://www.example.com/api/1/qc_decisions"
          }
        },
        "qc_files": {
          "actions": {
            "read": "http://www.example.com/api/1/qc_files"
          }
        },
        "qcable_creators": {
          "actions": {
            "read": "http://www.example.com/api/1/qcable_creators",
            "create": "http://www.example.com/api/1/qcable_creators"
          }
        },
        "qcables": {
          "actions": {
            "read": "http://www.example.com/api/1/qcables"
          }
        },
        "specific_tube_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/specific_tube_creations",
            "create": "http://www.example.com/api/1/specific_tube_creations"
          }
        },
        "tube_from_tube_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/tube_from_tube_creations",
            "create": "http://www.example.com/api/1/tube_from_tube_creations"
          }
        },
        "custom_metadatum_collections": {
          "actions": {
            "read": "http://www.example.com/api/1/custom_metadatum_collections",
            "create": "http://www.example.com/api/1/custom_metadatum_collections"
          }
        },
        "volume_updates": {
          "actions": {
            "read": "http://www.example.com/api/1/volume_updates",
            "create": "http://www.example.com/api/1/volume_updates"
          }
        },
        "reference_genomes": {
          "actions": {
            "read": "http://www.example.com/api/1/reference_genomes",
            "create": "http://www.example.com/api/1/reference_genomes"
          }
        },
        "work_completions": {
          "actions": {
            "read": "http://www.example.com/api/1/work_completions",
            "create": "http://www.example.com/api/1/work_completions"
          }
        }
      }}
    }
    let(:response_code) { 200 }

    it 'lists the core actions' do
      api_request :get, subject
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end

  context '#get unauthorized' do
    let(:user) { create :user }

    let(:response_body) {
      %{{
        "revision": 2,

        "uuids": {
          "actions": {
            "lookup": "http://www.example.com/api/1/uuids/lookup",
            "bulk": "http://www.example.com/api/1/uuids/bulk"
          }
        },
        "searches": {
          "actions": {
            "read": "http://www.example.com/api/1/searches"
          }
        },

        "samples": {
          "actions": {
            "read": "http://www.example.com/api/1/samples"
          }
        },
        "sample_manifests": {
          "actions": {
          }
        },
        "suppliers": {
          "actions": {
            "read": "http://www.example.com/api/1/suppliers"
          }
        },

        "plate_purposes": {
          "actions": {
            "read": "http://www.example.com/api/1/plate_purposes"
          }
        },
        "tube_purposes": {
          "actions": {
            "read": "http://www.example.com/api/1/tube/purposes"
          }
        },
        "dilution_plate_purposes": {
          "actions": {
            "read": "http://www.example.com/api/1/dilution_plate_purposes"
          }
        },
        "extraction_attributes": {
          "actions": {
            "read": "http://www.example.com/api/1/extraction_attributes",
            "create": "http://www.example.com/api/1/extraction_attributes"
          }
        },
        "assets": {
          "actions": {
            "read": "http://www.example.com/api/1/assets"
          }
        },
        "asset_audits": {
          "actions": {
            "read": "http://www.example.com/api/1/asset_audits"
          }
        },
        "asset_groups": {
          "actions": {
            "read": "http://www.example.com/api/1/asset_groups"
          }
        },
        "tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/tubes"
          }
        },
        "sample_tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/sample_tubes"
          }
        },
        "library_tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/library_tubes"
          }
        },
        "library_events": {
          "actions": {
            "read": "http://www.example.com/api/1/library_events"
          }
        },
        "lot_types": {
          "actions": {
            "read": "http://www.example.com/api/1/lot_types"
          }
        },
        "lots": {
          "actions": {
            "read": "http://www.example.com/api/1/lots"
          }
        },
        "multiplexed_library_tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/multiplexed_library_tubes"
          }
        },
        "plates": {
          "actions": {
            "read": "http://www.example.com/api/1/plates"
          }
        },
        "wells": {
          "actions": {
            "read": "http://www.example.com/api/1/wells"
          }
        },
        "lanes": {
          "actions": {
            "read": "http://www.example.com/api/1/lanes"
          }
        },

        "request_types": {
          "actions": {
            "read": "http://www.example.com/api/1/request_types"
          }
        },
        "requests": {
          "actions": {
            "read": "http://www.example.com/api/1/requests"
          }
        },
        "multiplexed_library_creation_requests": {
          "actions": {
            "read": "http://www.example.com/api/1/multiplexed_library_creation_requests"
          }
        },
        "library_creation_requests": {
          "actions": {
            "read": "http://www.example.com/api/1/library_creation_requests"
          }
        },
        "sequencing_requests": {
          "actions": {
            "read": "http://www.example.com/api/1/sequencing_requests"
          }
        },

        "order_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/order_templates"
          }
        },
        "submissions": {
          "actions": {
            "read": "http://www.example.com/api/1/submissions",
            "create": "http://www.example.com/api/1/submissions"
          }
        },
       "submission_pools": {
          "actions": {
            "read": "http://www.example.com/api/1/submission_pools"
          }
        },
        "orders": {
          "actions": {
            "read": "http://www.example.com/api/1/orders"
          }
        },

        "studies": {
          "actions": {
            "read": "http://www.example.com/api/1/studies"
          }
        },
        "projects": {
          "actions": {
            "read": "http://www.example.com/api/1/projects"
          }
        },

        "pipelines": {
          "actions": {
            "read": "http://www.example.com/api/1/pipelines"
          }
        },
        "plate_conversions": {
          "actions": {
            "read": "http://www.example.com/api/1/plate_conversions"
          }
        },
        "plate_templates":
           {"actions": {"read": "http://www.example.com/api/1/plate_templates"}},
        "batches": {
          "actions": {
            "read": "http://www.example.com/api/1/batches"
          }
        },
        "robots": {"actions": {"read": "http://www.example.com/api/1/robots"}},
        "stamps":{
          "actions":{
            "read":"http://www.example.com/api/1/stamps"
          }
        },
        "transfers": {
          "actions": {
            "read": "http://www.example.com/api/1/transfers"
          }
        },
        "transfer_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/transfer_templates"
          }
        },
        "tag_groups": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_groups"
          }
        },

        "tag_layouts": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_layouts"
          }
        },
        "tag2_layouts": {
          "actions": {
            "read": "http://www.example.com/api/1/tag2_layouts"
          }
        },
        "tag_layout_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_layout_templates"
          }
        },
        "tag2_layout_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/tag2_layout_templates"
          }
        },
        "plate_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/plate_creations"
          }
        },
        "tube_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/tube_creations"
          }
        },
        "state_changes": {
          "actions": {
            "read": "http://www.example.com/api/1/state_changes"
          }
        },
        "bait_library_layouts": {
          "actions": {
            "read": "http://www.example.com/api/1/bait_library_layouts"
          }
        },

        "barcode_printers": {
          "actions": {
            "read": "http://www.example.com/api/1/barcode_printers"
          }
        },
        "users": {
          "actions": {
            "read": "http://www.example.com/api/1/users"
          }
        },
        "bulk_transfers": {
          "actions": {
            "read": "http://www.example.com/api/1/bulk_transfers"
          }
        },
        "comments": {
          "actions": {
          "read": "http://www.example.com/api/1/comments"
          }
        },
        "pooled_plate_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/pooled_plate_creations"
          }
        },
        "qc_decisions": {
          "actions": {
            "read": "http://www.example.com/api/1/qc_decisions"
          }
        },
        "qc_files": {
          "actions": {
            "read": "http://www.example.com/api/1/qc_files"
          }
        },
        "qcable_creators": {
          "actions": {
            "read": "http://www.example.com/api/1/qcable_creators"
          }
        },
        "qcables": {
          "actions": {
            "read": "http://www.example.com/api/1/qcables"
          }
        },
        "specific_tube_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/specific_tube_creations"
          }
        },
        "tube_from_tube_creations": {
          "actions": {
            "read": "http://www.example.com/api/1/tube_from_tube_creations"
          }
        },
        "custom_metadatum_collections": {
          "actions": {
            "read": "http://www.example.com/api/1/custom_metadatum_collections"
          }
        },
        "volume_updates": {
          "actions": {
            "read": "http://www.example.com/api/1/volume_updates"
          }
        },
        "reference_genomes": {
          "actions": {
            "read": "http://www.example.com/api/1/reference_genomes"
          }
        },
        "work_completions": {
          "actions": {
            "read": "http://www.example.com/api/1/work_completions"
          }
        }
      }}
    }
    let(:response_code) { 200 }

    it 'lists the core actions' do
      user_api_request user, :get, subject
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end
end
