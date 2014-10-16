@api @json @asset @search @single-sign-on @new-api @barcode-service
Feature: Searching for a lot by batch id
  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given the UUID for the search "Find lot by batch id" is "00000000-1111-2222-3333-444444444444"

  @single
    Scenario: looking for a tag lot by batch id
    Given I have a lot type for testing called "Test Lot Type"
    And the tag layout template "Test tag layout" exists
    And the lot exists with the attributes:
    | lot_number | lot_type      | received_at | template        |
    | 1234567890 | Test Lot Type | 2014-02-01  | Test tag layout |
    And a plate template exists
    And I have a reporter lot type for testing called "Test Reporter Lot Type"
    And the lot exists with the attributes:
    | lot_number | lot_type               | received_at | template        |
    | 1234567891 | Test Reporter Lot Type | 2014-02-01  | testtemplate    |

    And I have a qc library created

      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "batch_id": "12345"
        }
      }
      """
    Then the HTTP response should be "301 Moved permanently"
    And the JSON should match the following for the specified fields:
    """
        {
          "lot":{
            "lot_number":"1234567890",
            "template_name":"Test tag layout"
          }
        }
    """

  @single
    Scenario: looking for a reporter lot by batch id
    Given I have a lot type for testing called "Test Lot Type"
    And the tag layout template "Test tag layout" exists
    And the lot exists with the attributes:
    | lot_number | lot_type      | received_at | template        |
    | 1234567890 | Test Lot Type | 2014-02-01  | Test tag layout |
    And a plate template exists
    And I have a reporter lot type for testing called "Test Reporter Lot Type"
    And the lot exists with the attributes:
    | lot_number | lot_type               | received_at | template        |
    | 1234567891 | Test Reporter Lot Type | 2014-02-01  | testtemplate    |

    And I have a qc library created
    And the library is testing a reporter

      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "batch_id": "12345"
        }
      }
      """
    Then the HTTP response should be "301 Moved permanently"
    And the JSON should match the following for the specified fields:
    """
        {
          "lot":{
            "lot_number":"1234567891",
            "template_name":"testtemplate"
          }
        }
    """
