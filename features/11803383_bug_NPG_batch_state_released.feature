@xml @api @allow-rescue
Feature: The XML for the sequencescape API. If all lanes are passed batch state is released
  Background:
    Given sequencescape is setup for 11803383
    And I am a "administrator" user logged in as "user"

  Scenario: POST XML to change qc_state on a asset
    Given I am on the last batch show page
    Then batch state should be "started"
    When I POST following XML to change in passed the QC state on the last asset:
       """
      <?xml version="1.0" encoding="UTF-8"?><qc_information><message>NPG change status in failed</message></qc_information>
       """
    Then the HTTP response should be "200"
    And ignoring "id|name|sample_id|parents" the XML response should be:
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <asset api_version="0.6">
          <id>458100</id>
          <type>Lane</type>
          <name>XXXXX 119650</name>
          <public_name></public_name>
          <sample_id>10857</sample_id>
          <qc_state>passed</qc_state>
          <children>
          </children>
          <parents>
            <id>119650</id>
          </parents>
          <requests>
          </requests>
        </asset>
        """
    Given I am on the last batch show page
    Then I should see "This batch belongs to pipeline: Cluster formation PE"
    And batch state should be "released"
