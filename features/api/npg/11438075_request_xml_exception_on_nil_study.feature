@npg @api @request @npg_request
Feature: A request with no study should not raise an exception when viewing the XML

  Background:
    Given all of this is happening at exactly "14-Feb-2011 23:00:00+01:00"

  Scenario: A request with a study
    Given I have a request 123 with a study 999
      And I am on the XML show page for request 123
    Then ignoring "read_length|asset_id|target_asset_id" the XML response should be:
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <request api_version="0.6">
      <id>123</id>
      <created_at>2011-02-14 22:00:00 +0000</created_at>
      <updated_at>2011-02-14 22:00:00 +0000</updated_at>
      <project_id>1</project_id>
      <study_id>999</study_id>

      <study_name>Study 999</study_name>
      <sample_id>1</sample_id>
      <template id="1">Library creation</template>
      <read_length>76</read_length>
      <asset_id>9</asset_id>
      <target_asset_id>7</target_asset_id>

      <state>pending</state>
      <properties>
      </properties>
      <user>abc123</user>
    </request>
    """
  
  Scenario: A request without a study
  Given I have a request 123 without a study
    And I am on the XML show page for request 123
  Then ignoring "read_length|asset_id|target_asset_id" the XML response should be:
  """
  <?xml version="1.0" encoding="UTF-8"?>
  <request api_version="0.6">
    <id>123</id>
    <created_at>2011-02-14 22:00:00 +0000</created_at>
    <updated_at>2011-02-14 22:00:00 +0000</updated_at>
    <project_id>1</project_id>
    <sample_id>1</sample_id>
    <template id="1">Library creation</template>
    <read_length>76</read_length>
    <asset_id>9</asset_id>
    <target_asset_id>1</target_asset_id>

    <state>pending</state>
    <properties>
    </properties>
    <user>abc123</user>
  </request>
  """
  
  Scenario: A request without a project
  Given I have a request 123 without a project
    And I am on the XML show page for request 123
  Then ignoring "read_length|asset_id|target_asset_id" the XML response should be:
  """
  <?xml version="1.0" encoding="UTF-8"?>
  <request api_version="0.6">
    <id>123</id>
    <created_at>2011-02-14 22:00:00 +0000</created_at>
    <updated_at>2011-02-14 22:00:00 +0000</updated_at>
    <study_id>999</study_id>

    <study_name>Study 999</study_name>
    <sample_id>1</sample_id>
    <template id="1">Library creation</template>
    <read_length>76</read_length>
    <asset_id>9</asset_id>
    <target_asset_id>1</target_asset_id>

    <state>pending</state>
    <properties>
    </properties>
    <user>abc123</user>
  </request>
  """
  
  Scenario: A request without a request type
    Given I have a request 123 without a request type
      And I am on the XML show page for request 123
    Then ignoring "read_length|asset_id|target_asset_id" the XML response should be:
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <request api_version="0.6">
      <id>123</id>
      <created_at>2011-02-14 22:00:00 +0000</created_at>
      <updated_at>2011-02-14 22:00:00 +0000</updated_at>
      <project_id>1</project_id>
      <study_id>999</study_id>

      <study_name>Study 999</study_name>
      <sample_id>1</sample_id>
      <read_length>76</read_length>
      <asset_id>9</asset_id>
      <target_asset_id>1</target_asset_id>

      <state>pending</state>
      <properties>
      </properties>
      <user>abc123</user>
    </request>
    """
