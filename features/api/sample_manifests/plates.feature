@api @json @sample_manifest @plate @single-sign-on @new-api @barcode-service
Feature: Access sample manifests through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual sample manifests through their UUID
  And I want to be able to perform other operations to individual sample manifests
  And I want to be able to do all of this only knowing the UUID of a sample manifest
  And I understand I will never be able to delete a sample manifest through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have an "active" study called "Testing sample manifests"
    And the UUID for the study "Testing sample manifests" is "22222222-3333-4444-5555-000000000000"

    Given a supplier called "John's Genes" with ID 2
    And the UUID for the supplier "John's Genes" is "33333333-1111-2222-3333-4444444444444"

    Given the "96 Well Plate" barcode printer "d999bc" exists
    And the plate barcode webservice returns "1234567"

  @read
  Scenario: Reading the JSON for a UUID
    Given the sample manifest exists with ID 1
    And the UUID for the sample manifest with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the sample manifest with ID 1 is owned by study "Testing sample manifests"
    And the sample manifest with ID 1 is supplied by "John's Genes"
    And the sample manifest with ID 1 is for 1 plate

    Given the sample manifest with ID 1 has been processed
    And all samples have a Sanger sample ID based on "WTCCC"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample_manifest": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            }
          },
          "supplier": {
            "actions": {
              "read": "http://www.example.com/api/1/33333333-1111-2222-3333-444444444444"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "last_errors": null,

          "samples": [
            { "sample": { "sanger": { "sample_id": "WTCCC02" } }, "container":{ "position": "A01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC03" } }, "container":{ "position": "B01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC04" } }, "container":{ "position": "C01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC05" } }, "container":{ "position": "D01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC06" } }, "container":{ "position": "E01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC07" } }, "container":{ "position": "F01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC08" } }, "container":{ "position": "G01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC09" } }, "container":{ "position": "H01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC10" } }, "container":{ "position": "A02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC11" } }, "container":{ "position": "B02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC12" } }, "container":{ "position": "C02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC13" } }, "container":{ "position": "D02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC14" } }, "container":{ "position": "E02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC15" } }, "container":{ "position": "F02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC16" } }, "container":{ "position": "G02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC17" } }, "container":{ "position": "H02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC18" } }, "container":{ "position": "A03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC19" } }, "container":{ "position": "B03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC20" } }, "container":{ "position": "C03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC21" } }, "container":{ "position": "D03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC22" } }, "container":{ "position": "E03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC23" } }, "container":{ "position": "F03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC24" } }, "container":{ "position": "G03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC25" } }, "container":{ "position": "H03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC26" } }, "container":{ "position": "A04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC27" } }, "container":{ "position": "B04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC28" } }, "container":{ "position": "C04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC29" } }, "container":{ "position": "D04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC30" } }, "container":{ "position": "E04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC31" } }, "container":{ "position": "F04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC32" } }, "container":{ "position": "G04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC33" } }, "container":{ "position": "H04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC34" } }, "container":{ "position": "A05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC35" } }, "container":{ "position": "B05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC36" } }, "container":{ "position": "C05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC37" } }, "container":{ "position": "D05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC38" } }, "container":{ "position": "E05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC39" } }, "container":{ "position": "F05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC40" } }, "container":{ "position": "G05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC41" } }, "container":{ "position": "H05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC42" } }, "container":{ "position": "A06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC43" } }, "container":{ "position": "B06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC44" } }, "container":{ "position": "C06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC45" } }, "container":{ "position": "D06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC46" } }, "container":{ "position": "E06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC47" } }, "container":{ "position": "F06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC48" } }, "container":{ "position": "G06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC49" } }, "container":{ "position": "H06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC50" } }, "container":{ "position": "A07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC51" } }, "container":{ "position": "B07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC52" } }, "container":{ "position": "C07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC53" } }, "container":{ "position": "D07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC54" } }, "container":{ "position": "E07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC55" } }, "container":{ "position": "F07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC56" } }, "container":{ "position": "G07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC57" } }, "container":{ "position": "H07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC58" } }, "container":{ "position": "A08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC59" } }, "container":{ "position": "B08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC60" } }, "container":{ "position": "C08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC61" } }, "container":{ "position": "D08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC62" } }, "container":{ "position": "E08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC63" } }, "container":{ "position": "F08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC64" } }, "container":{ "position": "G08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC65" } }, "container":{ "position": "H08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC66" } }, "container":{ "position": "A09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC67" } }, "container":{ "position": "B09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC68" } }, "container":{ "position": "C09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC69" } }, "container":{ "position": "D09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC70" } }, "container":{ "position": "E09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC71" } }, "container":{ "position": "F09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC72" } }, "container":{ "position": "G09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC73" } }, "container":{ "position": "H09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC74" } }, "container":{ "position": "A10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC75" } }, "container":{ "position": "B10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC76" } }, "container":{ "position": "C10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC77" } }, "container":{ "position": "D10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC78" } }, "container":{ "position": "E10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC79" } }, "container":{ "position": "F10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC80" } }, "container":{ "position": "G10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC81" } }, "container":{ "position": "H10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC82" } }, "container":{ "position": "A11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC83" } }, "container":{ "position": "B11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC84" } }, "container":{ "position": "C11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC85" } }, "container":{ "position": "D11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC86" } }, "container":{ "position": "E11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC87" } }, "container":{ "position": "F11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC88" } }, "container":{ "position": "G11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC89" } }, "container":{ "position": "H11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC90" } }, "container":{ "position": "A12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC91" } }, "container":{ "position": "B12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC92" } }, "container":{ "position": "C12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC93" } }, "container":{ "position": "D12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC94" } }, "container":{ "position": "E12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC95" } }, "container":{ "position": "F12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC96" } }, "container":{ "position": "G12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC97" } }, "container":{ "position": "H12", "barcode": "DN1234567T" } }
          ]
        }
      }
      """

  @update
  Scenario: Updating a manifest
    Given the sample manifest exists with ID 1
      And the UUID for the sample manifest with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the sample manifest with ID 1 is owned by study "Testing sample manifests"
      And the sample manifest with ID 1 is supplied by "John's Genes"
      And the sample manifest with ID 1 is for 1 plate

    Given the sample manifest with ID 1 has been processed
      And all samples have a Sanger sample ID based on "WTCCC"
      And all samples have sequential UUIDs based on "11111111-2222-3333-4444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample_manifest": {
          "samples": [
            {
              "uuid": "11111111-2222-3333-4444-000000000002",

              "supplier": {
                "sample_name": "flurby_wurby_sample",
                "measurements": {
                  "volume": "100",
                  "concentration": "10"
                }
              }
            }
          ]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample_manifest": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            }
          },
          "supplier": {
            "actions": {
              "read": "http://www.example.com/api/1/33333333-1111-2222-3333-444444444444"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "last_errors": null,

          "samples": [
            {
              "container": {
                "position": "A01",
                "barcode": "DN1234567T"
              },
              "sample": {
                "uuid": "11111111-2222-3333-4444-000000000002",
                "sanger": {
                  "sample_id": "WTCCC02"
                },
                "supplier": {
                  "sample_name": "flurby_wurby_sample",
                  "measurements": {
                    "volume": "100",
                    "concentration": "10"
                  }
                }
              }
            },

            { "sample": { "sanger": { "sample_id": "WTCCC03" } }, "container":{ "position": "B01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC04" } }, "container":{ "position": "C01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC05" } }, "container":{ "position": "D01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC06" } }, "container":{ "position": "E01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC07" } }, "container":{ "position": "F01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC08" } }, "container":{ "position": "G01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC09" } }, "container":{ "position": "H01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC10" } }, "container":{ "position": "A02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC11" } }, "container":{ "position": "B02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC12" } }, "container":{ "position": "C02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC13" } }, "container":{ "position": "D02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC14" } }, "container":{ "position": "E02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC15" } }, "container":{ "position": "F02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC16" } }, "container":{ "position": "G02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC17" } }, "container":{ "position": "H02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC18" } }, "container":{ "position": "A03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC19" } }, "container":{ "position": "B03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC20" } }, "container":{ "position": "C03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC21" } }, "container":{ "position": "D03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC22" } }, "container":{ "position": "E03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC23" } }, "container":{ "position": "F03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC24" } }, "container":{ "position": "G03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC25" } }, "container":{ "position": "H03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC26" } }, "container":{ "position": "A04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC27" } }, "container":{ "position": "B04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC28" } }, "container":{ "position": "C04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC29" } }, "container":{ "position": "D04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC30" } }, "container":{ "position": "E04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC31" } }, "container":{ "position": "F04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC32" } }, "container":{ "position": "G04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC33" } }, "container":{ "position": "H04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC34" } }, "container":{ "position": "A05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC35" } }, "container":{ "position": "B05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC36" } }, "container":{ "position": "C05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC37" } }, "container":{ "position": "D05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC38" } }, "container":{ "position": "E05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC39" } }, "container":{ "position": "F05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC40" } }, "container":{ "position": "G05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC41" } }, "container":{ "position": "H05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC42" } }, "container":{ "position": "A06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC43" } }, "container":{ "position": "B06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC44" } }, "container":{ "position": "C06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC45" } }, "container":{ "position": "D06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC46" } }, "container":{ "position": "E06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC47" } }, "container":{ "position": "F06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC48" } }, "container":{ "position": "G06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC49" } }, "container":{ "position": "H06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC50" } }, "container":{ "position": "A07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC51" } }, "container":{ "position": "B07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC52" } }, "container":{ "position": "C07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC53" } }, "container":{ "position": "D07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC54" } }, "container":{ "position": "E07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC55" } }, "container":{ "position": "F07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC56" } }, "container":{ "position": "G07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC57" } }, "container":{ "position": "H07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC58" } }, "container":{ "position": "A08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC59" } }, "container":{ "position": "B08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC60" } }, "container":{ "position": "C08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC61" } }, "container":{ "position": "D08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC62" } }, "container":{ "position": "E08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC63" } }, "container":{ "position": "F08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC64" } }, "container":{ "position": "G08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC65" } }, "container":{ "position": "H08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC66" } }, "container":{ "position": "A09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC67" } }, "container":{ "position": "B09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC68" } }, "container":{ "position": "C09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC69" } }, "container":{ "position": "D09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC70" } }, "container":{ "position": "E09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC71" } }, "container":{ "position": "F09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC72" } }, "container":{ "position": "G09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC73" } }, "container":{ "position": "H09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC74" } }, "container":{ "position": "A10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC75" } }, "container":{ "position": "B10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC76" } }, "container":{ "position": "C10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC77" } }, "container":{ "position": "D10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC78" } }, "container":{ "position": "E10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC79" } }, "container":{ "position": "F10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC80" } }, "container":{ "position": "G10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC81" } }, "container":{ "position": "H10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC82" } }, "container":{ "position": "A11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC83" } }, "container":{ "position": "B11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC84" } }, "container":{ "position": "C11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC85" } }, "container":{ "position": "D11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC86" } }, "container":{ "position": "E11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC87" } }, "container":{ "position": "F11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC88" } }, "container":{ "position": "G11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC89" } }, "container":{ "position": "H11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC90" } }, "container":{ "position": "A12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC91" } }, "container":{ "position": "B12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC92" } }, "container":{ "position": "C12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC93" } }, "container":{ "position": "D12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC94" } }, "container":{ "position": "E12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC95" } }, "container":{ "position": "F12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC96" } }, "container":{ "position": "G12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC97" } }, "container":{ "position": "H12", "barcode": "DN1234567T" } }
          ]
        }
      }
      """

  @create
  Scenario: Creating a plate sample manifest through a study
    Given the UUID of the next sample manifest created will be "00000000-1111-2222-3333-4444444444444"
    And the Sanger sample IDs will be sequentially generated

    When I POST the following JSON to the API path "/22222222-3333-4444-5555-000000000000/sample_manifests/create_for_plates":
      """
      {
        "sample_manifest": {
          "supplier": "33333333-1111-2222-3333-444444444444",
          "count": 1
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample_manifest": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            }
          },
          "supplier": {
            "actions": {
              "read": "http://www.example.com/api/1/33333333-1111-2222-3333-444444444444"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "last_errors": null,

          "samples": [
            { "sample": { "sanger": { "sample_id": "WTCCC1"  } }, "container":{ "position": "A01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC2"  } }, "container":{ "position": "B01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC3"  } }, "container":{ "position": "C01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC4"  } }, "container":{ "position": "D01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC5"  } }, "container":{ "position": "E01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC6"  } }, "container":{ "position": "F01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC7"  } }, "container":{ "position": "G01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC8"  } }, "container":{ "position": "H01", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC9"  } }, "container":{ "position": "A02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC10" } }, "container":{ "position": "B02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC11" } }, "container":{ "position": "C02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC12" } }, "container":{ "position": "D02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC13" } }, "container":{ "position": "E02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC14" } }, "container":{ "position": "F02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC15" } }, "container":{ "position": "G02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC16" } }, "container":{ "position": "H02", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC17" } }, "container":{ "position": "A03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC18" } }, "container":{ "position": "B03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC19" } }, "container":{ "position": "C03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC20" } }, "container":{ "position": "D03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC21" } }, "container":{ "position": "E03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC22" } }, "container":{ "position": "F03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC23" } }, "container":{ "position": "G03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC24" } }, "container":{ "position": "H03", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC25" } }, "container":{ "position": "A04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC26" } }, "container":{ "position": "B04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC27" } }, "container":{ "position": "C04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC28" } }, "container":{ "position": "D04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC29" } }, "container":{ "position": "E04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC30" } }, "container":{ "position": "F04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC31" } }, "container":{ "position": "G04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC32" } }, "container":{ "position": "H04", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC33" } }, "container":{ "position": "A05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC34" } }, "container":{ "position": "B05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC35" } }, "container":{ "position": "C05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC36" } }, "container":{ "position": "D05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC37" } }, "container":{ "position": "E05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC38" } }, "container":{ "position": "F05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC39" } }, "container":{ "position": "G05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC40" } }, "container":{ "position": "H05", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC41" } }, "container":{ "position": "A06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC42" } }, "container":{ "position": "B06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC43" } }, "container":{ "position": "C06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC44" } }, "container":{ "position": "D06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC45" } }, "container":{ "position": "E06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC46" } }, "container":{ "position": "F06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC47" } }, "container":{ "position": "G06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC48" } }, "container":{ "position": "H06", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC49" } }, "container":{ "position": "A07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC50" } }, "container":{ "position": "B07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC51" } }, "container":{ "position": "C07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC52" } }, "container":{ "position": "D07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC53" } }, "container":{ "position": "E07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC54" } }, "container":{ "position": "F07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC55" } }, "container":{ "position": "G07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC56" } }, "container":{ "position": "H07", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC57" } }, "container":{ "position": "A08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC58" } }, "container":{ "position": "B08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC59" } }, "container":{ "position": "C08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC60" } }, "container":{ "position": "D08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC61" } }, "container":{ "position": "E08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC62" } }, "container":{ "position": "F08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC63" } }, "container":{ "position": "G08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC64" } }, "container":{ "position": "H08", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC65" } }, "container":{ "position": "A09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC66" } }, "container":{ "position": "B09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC67" } }, "container":{ "position": "C09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC68" } }, "container":{ "position": "D09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC69" } }, "container":{ "position": "E09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC70" } }, "container":{ "position": "F09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC71" } }, "container":{ "position": "G09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC72" } }, "container":{ "position": "H09", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC73" } }, "container":{ "position": "A10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC74" } }, "container":{ "position": "B10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC75" } }, "container":{ "position": "C10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC76" } }, "container":{ "position": "D10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC77" } }, "container":{ "position": "E10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC78" } }, "container":{ "position": "F10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC79" } }, "container":{ "position": "G10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC80" } }, "container":{ "position": "H10", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC81" } }, "container":{ "position": "A11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC82" } }, "container":{ "position": "B11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC83" } }, "container":{ "position": "C11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC84" } }, "container":{ "position": "D11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC85" } }, "container":{ "position": "E11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC86" } }, "container":{ "position": "F11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC87" } }, "container":{ "position": "G11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC88" } }, "container":{ "position": "H11", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC89" } }, "container":{ "position": "A12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC90" } }, "container":{ "position": "B12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC91" } }, "container":{ "position": "C12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC92" } }, "container":{ "position": "D12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC93" } }, "container":{ "position": "E12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC94" } }, "container":{ "position": "F12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC95" } }, "container":{ "position": "G12", "barcode": "DN1234567T" } },
            { "sample": { "sanger": { "sample_id": "WTCCC96" } }, "container":{ "position": "H12", "barcode": "DN1234567T" } }
          ]
        }
      }
      """
