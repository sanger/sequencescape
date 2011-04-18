@sample @aliquoting
Feature: Sample aliquot from a 1D to a 2D tube.
  As a manager
  I want to move my sample from a 1D to 2D tube
  So I can use the 2D scanning to track the tube and the rack it is in

  Background: 
    Given I am an "Manager" user logged in as "abc123"
    And I have administrative role

    And I have an "active" study called "abc123_study"
    And the study have a workflow
    #And study "abc123_study" has asset and assetgroup
    And I have an "approved" project called "Project A"
    And the project "Project A" has quotas and quotas are enforced

    Given study "abc123_study" has the following registered samples in sample tubes:
      | sample       | sample tube    |
      | Sample123456 | AssetFor123456 |
      | Sample123457 | AssetFor123457 |
      | Sample123458 | AssetFor123458 |
      | Sample123459 | AssetFor123459 |

    Given a sample tube named "NewAssetFor123456" exists with a two dimensional barcode "SI123456"

    Given study "abc123_study" has made the following "Paired end sequencing" requests:
     |  state | count |    asset       | sample      |
     | pending|  1    | AssetFor123456 | Sample123456|
     | started|  1    | AssetFor123457 | Sample123457|
     | passed |  1    | AssetFor123458 | Sample123458|
     | failed |  1    | AssetFor123459 | Sample123459|

  Scenario: I can see the assets on the assets page
    Given I am visiting study "abc123_study" homepage
    And I follow "Assets"
    Then I should see "AssetFor123456"
    And I should see "AssetFor123457"
    And I should see "AssetFor123458"
    And I should see "AssetFor123459"

    When I follow "AssetFor123456"
    Then I should see "This asset has 1 request"
    And I should see "PENDING"

  Scenario: I can see the request on the sample page
    Given I am on the show page for sample "Sample123456"
    Then I should see "This sample is associated with 1 study"
    And I should see "This sample is associated with 1 asset"
    And I should see "Move sample to different study"

  Scenario:  the asset should have a request
    Given I am visiting study "abc123_study" homepage
    And I follow "Assets"
    And I follow "AssetFor123456"
    Then I should see "Back to study abc123_study"
    And I should see "This asset has 1 request"
    And I should see "PENDING"
    And I should see "Move asset to different study"
    And I should see "Move asset to 2D tube"

  Scenario: 2D barcode scanned and tube exists with an existing request
    Given I am visiting study "abc123_study" homepage
    And I follow "Assets"
    And I follow "AssetFor123456"
    When I follow "Move asset to 2D tube"
    Then I should see "Please scan the 2D tube you want to move the sample into"
    And I should not see "Scan your sample"
    And I should see a button marked "Submit"

    When I fill in "barcode_0" with "SI123456"
    And I press "Submit"
    Then I should see "Your sample has been successfully moved"
    And I should see "has 1 request"
    And I should see "PENDING"

  Scenario: 2D barcode scanned and tube does not exist
    Given I am visiting study "abc123_study" homepage
    And I follow "Assets"
    And I follow "AssetFor123456"
    When I follow "Move asset to 2D tube"
    Then I should see "Please scan the 2D tube you want to move the sample into"
    And I should not see "Scan your sample"
    And I should see a button marked "Submit"

    When I fill in "barcode_0" with "this is not a barcode"
    And I press "Submit"
    Then I should see "Your 2D tube has not been recognised"

  @wip
  Scenario: 2D barcode typed in

  @wip
  Scenario: Event has been created for source and destination tube

  Scenario: I cannot move the sample if the requests have gone past the pending state
    Given I am visiting study "abc123_study" homepage
    And I follow "Assets"
    And I follow "AssetFor123457"
    When I follow "Move asset to 2D tube"
    Then I should see "A sample cannot be moved to a 2D tube if it has any requests which are already started or have already been processed"
    And I should see "STARTED"

    Given I am visiting study "abc123_study" homepage
    And I follow "Assets"
    And I follow "AssetFor123458"
    When I follow "Move asset to 2D tube"
    Then I should see "A sample cannot be moved to a 2D tube if it has any requests which are already started or have already been processed" 
    And I should see "PASSED"

    Given I am visiting study "abc123_study" homepage
    And I follow "Assets"
    And I follow "AssetFor123459"
    When I follow "Move asset to 2D tube"
    Then I should see "A sample cannot be moved to a 2D tube if it has any requests which are already started or have already been processed"
    And I should see "FAILED"

  @wip
  Scenario: I try to move my sample to a 2D tube which already has a sample in it
