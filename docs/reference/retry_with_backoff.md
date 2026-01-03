# Retry an HTTP request with exponential backoff

Retry an HTTP request with exponential backoff

## Usage

``` r
retry_with_backoff(
  request_fn,
  max_retries = 5,
  base_delay = 1,
  max_delay = 60,
  description = "request"
)
```

## Arguments

- request_fn:

  Function that makes the HTTP request and returns response

- max_retries:

  Maximum number of retry attempts (default 5)

- base_delay:

  Initial delay in seconds (default 1)

- max_delay:

  Maximum delay in seconds (default 60)

- description:

  Description of the request for logging

## Value

The HTTP response if successful
