# ``TecoPaginationHelpers``

Pagination support for Tencent Cloud APIs. (Experimental)

## Overview

Some Tencent Cloud APIs provide query functionality and may return a list of objects with arbitrary length. Most of them come with support for paginating the list, i.e., they will return the list in fixed-size chunks, sometimes also with a token to be used in the next request.

This module provides experimental helpers on accessing the full paginated result either synchronously and asynchrously with `Teco`.

> This module is work-in-progress and APIs are subject to change at the moment. Please use at your own risk, and do not use it in production at the moment.
