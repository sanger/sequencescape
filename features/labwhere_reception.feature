@javascript
Feature: Labwhere reception
  Background:
    Given I am a "administrator" user logged in as "user"
    And I am on the homepage
  Scenario: Scan a plate, add plate's barcode to barcode list
    When I follow "Labwhere Reception"
    Then I should see "Labwhere Reception"
    When I fill in "asset_scan" with "1221234567841"
    Then I should see "1221234567841" within ".barcode_list"
    And I should see "Scanned: 1" within "#scanned"
  Scenario: Scan a plate twice, prevent duplicate barcodes in barcode list
    When I follow "Labwhere Reception"
    When I fill in "asset_scan" with "1221234567841"
    And I fill in "asset_scan" with "1221234567841"
    Then I should see "1221234567841" once
    And I should see "Scanned: 1" within "#scanned"
  Scenario: Counter of scanned assets is working properly
  	When I follow "Labwhere Reception"
    When I fill in "asset_scan" with "1221234567841"
    And I fill in "asset_scan" with "1221234567842"
    Then I should see "Scanned: 2" within "#scanned"
    When I follow first "Remove from list"
    Then I should see "Scanned: 1" within "#scanned"