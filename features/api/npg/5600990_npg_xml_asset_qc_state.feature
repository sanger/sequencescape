@xml @api @allow-rescue
Feature: The XML for the sequencescape API
  Background:
    Given sequencescape is setup for 5600990

  Scenario: POST XML to change qc_state on a asset
    When I POST following XML to change the QC state on the last asset:
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
          <name>ABC 119650</name>
          <public_name></public_name>
          <sample_id>10857</sample_id>
          <qc_state>failed</qc_state>
          <children>
          </children>
          <parents>
            <id>119650</id>
          </parents>
          <requests>
          </requests>
        </asset>
        """

  Scenario: POST XML to change qc_state on a asset
    When I POST following XML to change the QC state on the asset that does not exist:
       """
      <?xml version="1.0" encoding="UTF-8"?><qc_information><message>NPG change status in failed</message></qc_information>
       """
    Then the HTTP response should be "404"
    And ignoring "message" the XML response should be:
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <error><message>Could not find asset 1</message></error>
        """

  Scenario: POST XML to change qc_state on a asset. This asset has 2 requests. Should give you error.
    Given a second request
    When I POST following XML to change the QC state on the last asset:
       """
      <?xml version="1.0" encoding="UTF-8"?><qc_information><message>NPG change status in failed</message></qc_information>
       """
    Then the HTTP response should be "404"
    And ignoring "message" the XML response should be:
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <error><message>Unable to find a request for Lane: 1</message></error>
        """

  Scenario: POST XML to change qc_state on a asset. The relative request has a double refund
    Given a billing event to the request
    When I POST following XML to change the QC state on the last asset:
       """
      <?xml version="1.0" encoding="UTF-8"?><qc_information><message>NPG change status in failed</message></qc_information>
       """
    Then the HTTP response should be "500"
    And the XML response should be:
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <error><message>There was an error with BillingEvent.</message></error>
        """

  Scenario: POST XML to change qc_state on a asset. NPG did this action before
    Given an event to the request
    When I POST following XML to change the QC state on the last asset:
       """
      <?xml version="1.0" encoding="UTF-8"?><qc_information><message>NPG change status in failed</message></qc_information>
       """
    Then the HTTP response should be "500"
    And the XML response should be:
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <error><message>NPG user run this action. Please, contact USG</message></error>
        """
