# Modifying Schemas Managed By RedPanda

Each instance of RedPanda has a an admin web console which lets you take all actions on schemas in a visual editor.
The console can be accessed by appending `/console/` to the base URL of the RedPanda instance.
It will require authentication which can be found in the team password vault.
Only the Schema Registry section should be used in the console as we are not using the other parts of RedPanda.

New versions of schemas will need manually updating in the RedPanda console.

## Additional notes
- If a schema registry url is not provided Sequencescape will mock the connection to the schema registry, allowing local development and testing without requiring a live RedPanda instance.
