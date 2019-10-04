# @title API V1
# @deprecated We are currently in the process of migrating across to the v2 api.
# API V1

> API V1 should be considered deprecated
> We are currently in the process of migrating across to the v2 api.

The V1 api resides in `app/api` which contains four folders:

- core: Low level shared implementation, such as routing requests, parsing json
        and generating endpoints from the configuration.

- endpoints: The controller layer. Indicates the actions which can be performed
             on either the model (eg. api/v1/plates) or an instance.

- io: The view layer. Maps internal attributes to their external equivalent.

- model_extensions: These modules get included in the ActiveRecord classes and
                    should provide API specific methods. In practice lots of stuff
                    is included here.

Client use of the API is mostly handled via the
{http://www.github.com/sanger/sequencescape-client-api sequecescape-client-api gem}.

## Endpoints
An endpoint is created for each class which will be exposed via the API.
For example The class {Endpoints::Batches} handles calls to `api/vi/batches` as
well as individual {Batch} models.

@see {::Core::Endpoint::Base}

## IO
An endpoint is created for each ActiveRecord class and handles rendering of
outgoing json, and parsing of incoming JSON.

@see {::Core::Io::Base}

## Other Basic
API V1 routing is handled by an embedded Sinatra application {Api::RootService}.
This is mounted in the routes:
``mount Api::RootService.new => '/api/1'``
