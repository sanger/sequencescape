# @title API V2
# APIv2

The V2 api is a [JSON API](https://jsonapi.org/) based api using [JSONAPI::Resource](http://jsonapi-resources.com/).

## Extending the API
New resources can be added through a rails generator.
`bundle exec rails generate api_v2`
For more information run the command above for details of how to use it, and what files it will generate.

## Resources
Describe the attributes and relationships exposed on each resource, as well as specifying filters.

## Controllers
Controller behaviour is usually handled by JSONAPI::Resource, so most controllers lack any custom behaviour.

## Exporting API definition
A [devour](https://github.com/twg/devour) compatible API specification can be exported via the rake task:
`bundle exec rake devour:create_config`
