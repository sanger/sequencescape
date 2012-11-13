@api @json @root @single-sign-on @new-api
Feature: The entry point for the API gives directions to the other actions
  In order to be able to determine what I can do with the API
  As an authenticated user of the API
  I want to be able to HTTP GET one URL and get all available actions

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  Scenario: Retrieving the root entry point when unauthorised
    When I GET the API path "/"
    Then the HTTP response should be "200 OK"
    Then show me the HTTP response body
    And the JSON should be:
      """
      {
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
            "read": "http://www.example.com/api/1/tag_layouts"
          }
        },
        "tag_layout_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_layout_templates"
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
        }
      }
      """

  @authorised
  Scenario: Retrieving the root entry point when authorised
    When I make an authorised GET the API path "/"
    Then the HTTP response should be "200 OK"
    And the JSON should be:
      """
      {
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
        "library_tubes": {
          "actions": {
            "read": "http://www.example.com/api/1/library_tubes"
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
            "read": "http://www.example.com/api/1/tag_layouts"
          }
        },
        "tag_layout_templates": {
          "actions": {
            "read": "http://www.example.com/api/1/tag_layout_templates"
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
        }
      }
      """

