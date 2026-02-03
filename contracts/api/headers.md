# HTTP Headers - VoiceMock AI Interview Coach

This document defines the standard HTTP headers used in API requests and responses.

## Request Headers

| Header            | Required | Description                                   |
|-------------------|----------|-----------------------------------------------|
| Content-Type      | Yes      | `multipart/form-data` for audio, `application/json` for JSON |
| Accept            | No       | Should be `application/json`                  |
| X-Session-Token   | Yes*     | Session token (required after `/session/start`) |

## Response Headers

| Header            | Always   | Description                                   |
|-------------------|----------|-----------------------------------------------|
| Content-Type      | Yes      | Always `application/json` for API responses   |
| X-Request-ID      | Yes      | Unique request identifier (Server-generated)  |
| X-Stage           | On error | Processing stage where error occurred         |

## X-Request-ID

The server generates a unique `X-Request-ID` for every response. This ID:
- Is a UUID v4 format string
- Appears in the response header AND response body
- Should be logged by clients for debugging
- Must be included in bug reports

### Example

```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: 550e8400-e29b-41d4-a716-446655440000

{
  "data": { ... },
  "error": null,
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

## X-Session-Token

After calling `POST /session/start`, the server returns a session token.
All subsequent requests must include this token.

### Example Flow

1. Start session:
```http
POST /session/start
Content-Type: application/json

{"job_type": "Backend Engineer", "focus_area": "System Design"}
```

2. Response includes token:
```json
{
  "data": {
    "session_id": "sess_abc123",
    "token": "eyJhbGciOi..."
  }
}
```

3. Subsequent requests:
```http
POST /turn
X-Session-Token: eyJhbGciOi...
Content-Type: multipart/form-data
```

## CORS Headers (Development)

For local development, the API includes:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, X-Session-Token`
