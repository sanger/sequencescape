@api @json @uk10k @cancer @order @submission @single-sign-on @new-api
Feature: Creating submissions
  In order to get samples sequenced
  As a member of the UK10k project
  I need to be able to create orders from templates
  And I need to be able to add these orders to a submission
  And I need to be able to attach assets to these submissions
  And I need to be able to get a submission submitted

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have an "active" study called "Testing submission creation"
    And the UUID for the study "Testing submission creation" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing submission creation"
    And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"

    Given the UUID for the order template "Illumina-C - Library creation - Paired end sequencing" is "00000000-1111-2222-3333-444444444444"
    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

    Given the UUID for the request type "Library creation" is "99999999-1111-2222-3333-000000000000"
    And the UUID for the request type "Paired end sequencing" is "99999999-1111-2222-3333-000000000001"

    @multiple_order
  Scenario: Creating a submission with multiple orders
    Given 4 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000001, 33333333-4444-5555-6666-000000000002                                 |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    Given the UUID of the next order created will be "11111111-2222-3333-4444-666666666667"
    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000003, 33333333-4444-5555-6666-000000000004                                 |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    When I POST the following JSON to the API path "/submissions":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666",
            "11111111-2222-3333-4444-666666666667"
          ]
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },
          "orders": [
            { "uuid": "11111111-2222-3333-4444-666666666666" },
            { "uuid": "11111111-2222-3333-4444-666666666667" }
          ]
        }
      }
      """

  @create @error @asset
  Scenario: Attempting to create a submission with an order that has no assets
    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    When I POST the following JSON to the API path "/submissions":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666"
          ]
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "orders.assets": [ "can't be blank" ]
        }
      }
      """

  @update @error @asset
  Scenario: Attempting to add an order that has no assets to an existing submission
    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
    Given I have an empty submission

    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-555555555555":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666"
          ]
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    # Previously this was: {"content":{"orders.assets": [ "can't be blank" ]}} which was nicer.
    # However Rails 3 makes this tricker, by validating the order the moment it is added to submission
    And the JSON should be:
      """
      {
        "content": "Failed to replace orders because one or more of the new records could not be saved."
      }
      """

  @submit @error
  Scenario Outline: Attempting to submit a submission that has been readied
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Illumina-C - Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission
    And the state of the submission with UUID "11111111-2222-3333-4444-555555555555" is "<state>"

    When I GET the API path "/11111111-2222-3333-4444-555555555555"
    Then the HTTP response should be "200 OK"
    And the JSON "submission.actions" should be exactly:
      """
      {
        "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
      }
      """

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "501 Not Implemented"
    And the JSON should match the following for the specified fields:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """
    And there should be no submissions to be processed

    Examples:
      | state      |
      | pending    |
      | processing |
      | ready      |
      | failed     |
