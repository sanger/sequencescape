@api @json @barcode_printer @single-sign-on @new-api
Feature: Access barcode printers through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual barcode printers through their UUID
  And I want to be able to perform other operations to individual barcode printers
  And I want to be able to do all of this only knowing the UUID of a barcode printer
  And I understand I will never be able to delete a barcode printer through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario Outline: Reading the JSON for a barcode printer
    Given the "<printer_type>" barcode printer "<printer_type> printer" exists
      And the UUID for the barcode printer "<printer_type> printer" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "barcode_printer": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "<printer_type> printer",
          "active": true,
          "service": {
            "url": "http://localhost:9998/barcode_service.wsdl"
          },
          "type": {
            "name": "<printer_type>",
            "layout": <label_layout>
          }
        }
      }
      """

    Scenarios:
      | printer_type   | label_layout |
      | 1D Tube        | 2            |
      | 96 Well Plate  | 1            |
      | 384 Well Plate | 6            |
