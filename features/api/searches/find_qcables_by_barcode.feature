@api @json @user @search @single-sign-on @new-api @barcode_search @barcode-service
Feature: Searching for qcables by asset barcode
  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given the UUID for the search "Find qcable by barcode" is "00000000-1111-2222-3333-444444444444"

    Given I have a lot type for testing called "Test Lot Type"
      And the tag layout template "Test tag layout" exists
      And the lot exists with the attributes:
      | lot_number | lot_type      | received_at | template        |
      | 1234567890 | Test Lot Type | 2014-02-01  | Test tag layout |
      And I have two qcables


  @single
    Scenario: looking for a single barcode

      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "barcode": "1221000001777"
        }
      }
      """
    Then the HTTP response should be "301 Moved permanently"
    And the JSON should match the following for the specified fields:
    """
        {
          "qcable":{
            "state": "created",
            "barcode" : {
              "ean13" : "1221000001777"
            }
          }
        }
    """

  @multiple
    Scenario: looking for multiple barcodes

      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
      """
      {
        "search": {
          "barcode": ["1221000001777","1221000002781"]
        }
      }
      """
    Then the HTTP response should be "300 Multiple Choices"
    And the JSON should match the following for the specified fields:
    """
        {
          "searches":[
          {
            "state": "created",
            "barcode" : {
              "ean13" : "1221000001777"
            }
          },
          {
            "state": "created",
            "barcode" : {
              "ean13" : "1221000002781"
            }
          }
          ]
        }
    """
