@custom_text
Feature:  Site Wide Information Box
  In order to inform users of upcoming events such as redeployment
  As a administrator
  I want to set a short message and have it displayed on every page


  Background:
    Given I am an "administrator" user logged in as "Joe Bloggs"
      And I am on the custom texts admin page
      # This should be set up via DB seeds...
      And there is a CustomText with identifier: "app_info_box", differential: "1"
     When I edit the CustomText
     Then I should see "EDIT CUSTOM TEXT"
      And the field labeled "Custom text identifier" should contain "app_info_box"
      And the field labeled "Custom text differential" should contain "1"
      And the field labeled "Custom text content type" should contain "text/html"

  Scenario: Entering a new message
  # Note: We have to use the field name here as the XPATH form helpers allow partial
  # matches for labels. This caused us to fill in the content type field.
    Given I fill in "custom_text[content]" with "Something, something, darkside..."
      And I press "Save Custom text"
    When I go to the homepage
    Then the application information box should contain "Something, something, darkside..."


  Scenario: Entering a blank message should hide the application information box
    Given I fill in "custom_text[content]" with ""
      And I press "Save Custom text"
    When I go to the homepage
    Then the application information box is not shown
