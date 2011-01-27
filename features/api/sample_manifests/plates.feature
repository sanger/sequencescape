@api @json @sample_manifest @plate @single-sign-on @new-api @barcode-service
Feature: Access sample manifests through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual sample manifests through their UUID
  And I want to be able to perform other operations to individual sample manifests
  And I want to be able to do all of this only knowing the UUID of a sample manifest
  And I understand I will never be able to delete a sample manifest through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

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
        sample_manifest: {
          actions: {
            read: "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          study: {
            actions: {
              read: "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            }
          },
          supplier: {
            actions: {
              read: "http://www.example.com/api/1/33333333-1111-2222-3333-444444444444"
            }
          },

          uuid: "00000000-1111-2222-3333-444444444444",
          state: "pending",
          last_errors: null,

          samples: [
            { "sanger_sample_id": "WTCCC01", "container":{ "well": "A01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC02", "container":{ "well": "B01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC03", "container":{ "well": "C01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC04", "container":{ "well": "D01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC05", "container":{ "well": "E01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC06", "container":{ "well": "F01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC07", "container":{ "well": "G01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC08", "container":{ "well": "H01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC09", "container":{ "well": "A02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC10", "container":{ "well": "B02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC11", "container":{ "well": "C02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC12", "container":{ "well": "D02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC13", "container":{ "well": "E02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC14", "container":{ "well": "F02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC15", "container":{ "well": "G02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC16", "container":{ "well": "H02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC17", "container":{ "well": "A03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC18", "container":{ "well": "B03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC19", "container":{ "well": "C03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC20", "container":{ "well": "D03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC21", "container":{ "well": "E03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC22", "container":{ "well": "F03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC23", "container":{ "well": "G03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC24", "container":{ "well": "H03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC25", "container":{ "well": "A04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC26", "container":{ "well": "B04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC27", "container":{ "well": "C04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC28", "container":{ "well": "D04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC29", "container":{ "well": "E04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC30", "container":{ "well": "F04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC31", "container":{ "well": "G04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC32", "container":{ "well": "H04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC33", "container":{ "well": "A05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC34", "container":{ "well": "B05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC35", "container":{ "well": "C05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC36", "container":{ "well": "D05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC37", "container":{ "well": "E05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC38", "container":{ "well": "F05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC39", "container":{ "well": "G05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC40", "container":{ "well": "H05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC41", "container":{ "well": "A06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC42", "container":{ "well": "B06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC43", "container":{ "well": "C06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC44", "container":{ "well": "D06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC45", "container":{ "well": "E06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC46", "container":{ "well": "F06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC47", "container":{ "well": "G06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC48", "container":{ "well": "H06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC49", "container":{ "well": "A07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC50", "container":{ "well": "B07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC51", "container":{ "well": "C07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC52", "container":{ "well": "D07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC53", "container":{ "well": "E07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC54", "container":{ "well": "F07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC55", "container":{ "well": "G07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC56", "container":{ "well": "H07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC57", "container":{ "well": "A08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC58", "container":{ "well": "B08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC59", "container":{ "well": "C08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC60", "container":{ "well": "D08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC61", "container":{ "well": "E08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC62", "container":{ "well": "F08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC63", "container":{ "well": "G08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC64", "container":{ "well": "H08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC65", "container":{ "well": "A09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC66", "container":{ "well": "B09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC67", "container":{ "well": "C09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC68", "container":{ "well": "D09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC69", "container":{ "well": "E09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC70", "container":{ "well": "F09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC71", "container":{ "well": "G09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC72", "container":{ "well": "H09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC73", "container":{ "well": "A10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC74", "container":{ "well": "B10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC75", "container":{ "well": "C10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC76", "container":{ "well": "D10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC77", "container":{ "well": "E10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC78", "container":{ "well": "F10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC79", "container":{ "well": "G10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC80", "container":{ "well": "H10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC81", "container":{ "well": "A11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC82", "container":{ "well": "B11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC83", "container":{ "well": "C11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC84", "container":{ "well": "D11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC85", "container":{ "well": "E11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC86", "container":{ "well": "F11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC87", "container":{ "well": "G11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC88", "container":{ "well": "H11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC89", "container":{ "well": "A12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC90", "container":{ "well": "B12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC91", "container":{ "well": "C12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC92", "container":{ "well": "D12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC93", "container":{ "well": "E12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC94", "container":{ "well": "F12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC95", "container":{ "well": "G12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC96", "container":{ "well": "H12", "barcode": "DN1234567T" } }
          ]
        },
        uuids_to_ids: {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """

  @create
  Scenario: Creating a plate sample manifest through a study
    Given the UUID of the next sample manifest created will be "00000000-1111-2222-3333-4444444444444"
    And the Sanger sample IDs will be sequentially generated

    When I POST the following JSON to the API path "/22222222-3333-4444-5555-000000000000/sample_manifests/create_for_plate":
      """
      {
        sample_manifest: {
          supplier: "33333333-1111-2222-3333-444444444444",
          count: 1
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        sample_manifest: {
          actions: {
            read: "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          study: {
            actions: {
              read: "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            }
          },
          supplier: {
            actions: {
              read: "http://www.example.com/api/1/33333333-1111-2222-3333-444444444444"
            }
          },

          uuid: "00000000-1111-2222-3333-444444444444",
          state: "pending",
          last_errors: null,

          samples: [
            { "sanger_sample_id": "WTCCC1",  "container":{ "well": "A01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC2",  "container":{ "well": "B01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC3",  "container":{ "well": "C01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC4",  "container":{ "well": "D01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC5",  "container":{ "well": "E01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC6",  "container":{ "well": "F01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC7",  "container":{ "well": "G01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC8",  "container":{ "well": "H01", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC9",  "container":{ "well": "A02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC10", "container":{ "well": "B02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC11", "container":{ "well": "C02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC12", "container":{ "well": "D02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC13", "container":{ "well": "E02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC14", "container":{ "well": "F02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC15", "container":{ "well": "G02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC16", "container":{ "well": "H02", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC17", "container":{ "well": "A03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC18", "container":{ "well": "B03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC19", "container":{ "well": "C03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC20", "container":{ "well": "D03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC21", "container":{ "well": "E03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC22", "container":{ "well": "F03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC23", "container":{ "well": "G03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC24", "container":{ "well": "H03", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC25", "container":{ "well": "A04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC26", "container":{ "well": "B04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC27", "container":{ "well": "C04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC28", "container":{ "well": "D04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC29", "container":{ "well": "E04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC30", "container":{ "well": "F04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC31", "container":{ "well": "G04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC32", "container":{ "well": "H04", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC33", "container":{ "well": "A05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC34", "container":{ "well": "B05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC35", "container":{ "well": "C05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC36", "container":{ "well": "D05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC37", "container":{ "well": "E05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC38", "container":{ "well": "F05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC39", "container":{ "well": "G05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC40", "container":{ "well": "H05", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC41", "container":{ "well": "A06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC42", "container":{ "well": "B06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC43", "container":{ "well": "C06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC44", "container":{ "well": "D06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC45", "container":{ "well": "E06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC46", "container":{ "well": "F06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC47", "container":{ "well": "G06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC48", "container":{ "well": "H06", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC49", "container":{ "well": "A07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC50", "container":{ "well": "B07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC51", "container":{ "well": "C07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC52", "container":{ "well": "D07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC53", "container":{ "well": "E07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC54", "container":{ "well": "F07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC55", "container":{ "well": "G07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC56", "container":{ "well": "H07", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC57", "container":{ "well": "A08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC58", "container":{ "well": "B08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC59", "container":{ "well": "C08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC60", "container":{ "well": "D08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC61", "container":{ "well": "E08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC62", "container":{ "well": "F08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC63", "container":{ "well": "G08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC64", "container":{ "well": "H08", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC65", "container":{ "well": "A09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC66", "container":{ "well": "B09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC67", "container":{ "well": "C09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC68", "container":{ "well": "D09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC69", "container":{ "well": "E09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC70", "container":{ "well": "F09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC71", "container":{ "well": "G09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC72", "container":{ "well": "H09", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC73", "container":{ "well": "A10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC74", "container":{ "well": "B10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC75", "container":{ "well": "C10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC76", "container":{ "well": "D10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC77", "container":{ "well": "E10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC78", "container":{ "well": "F10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC79", "container":{ "well": "G10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC80", "container":{ "well": "H10", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC81", "container":{ "well": "A11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC82", "container":{ "well": "B11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC83", "container":{ "well": "C11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC84", "container":{ "well": "D11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC85", "container":{ "well": "E11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC86", "container":{ "well": "F11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC87", "container":{ "well": "G11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC88", "container":{ "well": "H11", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC89", "container":{ "well": "A12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC90", "container":{ "well": "B12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC91", "container":{ "well": "C12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC92", "container":{ "well": "D12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC93", "container":{ "well": "E12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC94", "container":{ "well": "F12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC95", "container":{ "well": "G12", "barcode": "DN1234567T" } },
            { "sanger_sample_id": "WTCCC96", "container":{ "well": "H12", "barcode": "DN1234567T" } }
          ]
        }
      }
      """
