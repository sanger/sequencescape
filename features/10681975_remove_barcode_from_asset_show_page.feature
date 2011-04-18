@asset
Feature: Barcode should not appear in the asset view

Background: 
  Given I am logged in as "me"   
  And I am on the homepage

  Scenario: the goal is rename sample and asset
    Given an asset with name "MyAssetName", EAN barcode "9999999"
    When I am on the show page for asset "MyAssetName"
    Then I should not see "EAN13 barcode:"  
    