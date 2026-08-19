# @title Sequencescape API V2

# Sequencescape API V2

The V2 API is a [JSON API](https://jsonapi.org/) based API implemented using [JSONAPI::Resource](http://jsonapi-resources.com/).

## Authentication

Key-based authentication is required for access to all endpoints, details of which can be found at [API V2 Authentication](https://github.com/sanger/sequencescape/blob/develop/README.md#api-v2-authentication).

## Resources and endpoints

The following JSON:API resources are exposed under `/api/v2`:

<iframe
	src="/doc/Api/V2"
	title="YARD Module: Api::V2"
	style="width:100%;min-height:720px;border:1px solid #ddd;border-radius:4px;"
></iframe>

If the embedded view does not render, open the module page directly:
[Module: Api::V2](/doc/Api/V2)

## Extending the API

New resources can be added through a rails generator.
`bundle exec rails generate api_v2`
For more information run the command above for details of how to use it, and what files it will generate.

## Resources

Describes the attributes and relationships exposed on each resource, as well as specifying filters.

## Controllers

Controller behaviour is usually handled by JSONAPI::Resource, so most controllers lack any custom behaviour.

## Exporting API definition

A [devour](https://github.com/twg/devour) compatible API specification can be exported via the rake task:
`bundle exec rake devour:create_config`
