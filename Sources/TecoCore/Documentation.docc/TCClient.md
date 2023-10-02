# ``TCClient``

## Discussions

Some Tencent Cloud APIs provide query functionality and may return a list of objects with arbitrary length. Most of them come with support for paginating the list, i.e., they will return the list in fixed-size chunks, sometimes also with a token to be used in the next request.

``TCClient`` has integrated support for accessing the full paginated results either synchronously and asynchrously, through pagination and paginator APIs.

## Topics

### Configurating the Client

- ``init(credentialProvider:retryPolicy:options:httpClientProvider:logger:)``

- ``HTTPClientProvider``
- ``Options``

- ``credentialProvider``
- ``retryPolicy``
- ``eventLoopGroup``
- ``httpClient``

### Executing an API Request

- ``execute(action:path:region:httpMethod:serviceConfig:skipAuthorization:outputs:logger:on:)``
- ``execute(action:path:region:httpMethod:serviceConfig:skipAuthorization:input:outputs:logger:on:)-1aise``
- ``execute(action:path:region:httpMethod:serviceConfig:skipAuthorization:input:outputs:logger:on:)-63804``

### Executing a Paginated Request

- ``paginate(input:region:command:initialValue:reducer:logger:on:)``
- ``paginate(input:region:command:logger:on:)``
- ``paginate(input:region:command:callback:logger:on:)``

### Retrieving Paginated Results 

- ``Paginator``
- ``PaginatorSequences``
- ``Paginator/makeAsyncSequences(input:region:command:logger:on:)``

### Shutting Down the Client

- ``shutdown(queue:_:)``
- ``syncShutdown()``

### Utilities

- ``loggingDisabled``
- ``getCredential(on:logger:)``
- ``signHeaders(url:method:headers:body:serviceConfig:skipAuthorization:logger:)``
- ``signHeaders(url:httpMethod:headers:body:serviceConfig:skipAuthorization:logger:)``
