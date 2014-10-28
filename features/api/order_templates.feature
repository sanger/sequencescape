@api @json @order @single-sign-on @new-api
Feature: Access order templates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual order templates through their UUID
  And I want to be able to perform other operations to individual order templates
  And I want to be able to do all of this only knowing the UUID of a order template
  And I understand I will never be able to delete a order template through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given no order templates exist

  @read
  Scenario: Reading all of the order templates that the system has
    Given an order template called "Simple sequencing" with UUID "00000000-1111-2222-3333-444444444444"
    When I GET the API path "/order_templates"
    Then the HTTP response should be "200 OK"

  @read
  Scenario: Reading the JSON for a UUID
    Given an order template called "Simple sequencing" with UUID "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "order_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "orders": {
            "actions": {
              "create": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/orders"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Simple sequencing"
        }
      }
      """
