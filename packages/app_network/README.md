# app_network

Package-only API-request infrastructure with injected host contracts. Import
`package:app_network/app_network.dart`. It does not implement backend endpoints,
JWT parsing, storage plugins, navigation, or an app-wide BLoC.

## Host contracts and construction

- Supply a `NetworkTransport` or construct `DioNetworkTransport` with a trusted
  HTTP(S) `baseUri`. The Dio transport creates a dedicated client, disables
  redirects, rejects cross-origin URLs and returns all HTTP statuses.
- For protected requests, supply `AuthSession` with a `TokenStore`, `AuthMode`,
  an `onUnauthorized` callback, and optionally a `TokenRefresher`.
- Give that session to `AppNetworkClient`; multiple clients may share it.
- The host implements `TokenStore.read/write/clear` using its chosen secure
  storage. Operations return `NetworkResult`; thrown host exceptions are mapped
  to sanitized failures. Writes must atomically replace the complete credentials.
- The host implements `TokenRefresher.refresh`. It owns endpoint URLs, response
  validation, expiry semantics and rotation/preservation of the refresh token.
  Return complete `NetworkCredentials`. An empty token is rejected at construction;
  validate all backend fields and return a typed failure on invalid responses.
- Refresh MUST use a raw/public transport or independent client, never the
  authenticated client sharing the session. Recursive refresh can deadlock.

There is deliberately no concrete backend contract or runnable app example.

## Three request flows

### Refresh-token protected

Use `AuthMode.refreshToken` and `RequestAuth.protected`. Credentials are restored
once from the host store. The default policy attaches `Authorization: Bearer
<access token>` per request and treats HTTP 401 as an auth rejection. Refresh
credentials are supplied only to the host refresher, never attached to normal
requests. Configure `AuthPolicy.headerName`, `headerBuilder` and `isRejected` for
another backend mechanism; no JWT/body/403 inference is performed by default.

Concurrent expired requests share one refresh for that token revision. Complete
replacement credentials are persisted before waiters are released. Late old-token
rejections reuse the newer revision. Eligible requests replay at most once; a
replayed auth rejection is terminal and cannot start another refresh.

### Access-token-only protected

Use `AuthMode.accessTokenOnly`. Auth rejection clears credentials and notifies
the host; it never refreshes or replays. Refresh-token mode without a refresher
or refresh credential falls back to the same clear-and-notify behavior.

### Public

Use `RequestAuth.public`. No token-store read, credential injection, refresh or
logout notification occurs, even on public HTTP 401 or after the protected
session is closed. A public-only client needs no `AuthSession`. The client
sanitizes both Authorization and the configured auth header from public requests.

## Requests, results and decoding

Create `NetworkRequest` with explicit `path` and `auth`, plus method, query,
headers and buffered JSON body as needed. Maps/lists are deep-frozen at creation
so caller mutation cannot change the replay payload. Buffered multipart uploads
use `NetworkMultipart` with immutable fields and `NetworkUpload` bytes;
pass `responseBytes: true` when downloading binary content. Streams, raw
FormData, non-JSON objects and non-finite numbers are rejected. Only same-origin URLs are
allowed by Dio. NetworkRequest constructor errors are programming errors; runtime
operations return typed outcomes.

Call `client.send<T>(request, decode: ...)`. The host decoder receives the raw
successful payload and returns T. Use exhaustive pattern matching on
`NetworkSuccess<NetworkResponse<T>>` and `NetworkError<NetworkResponse<T>>`.
Non-2xx HTTP responses are typed HTTP failures with status only; ordinary
403/5xx/transport failures do not trigger auth logic. The injected classifier can
classify other HTTP responses. Decoder errors become decoding failures; policy
callback errors remain callback failures, not silently successful responses.

`NetworkFailureKind` distinguishes HTTP, connectivity, timeout, cancellation,
decoding, storage, refresh, unauthorized, replayDenied, staleSession,
invalidRequest and callback failures. Secondary cleanup failures are retained
without replacing the primary reason. No raw exception, request URL, headers,
body or credential is included in package diagnostics. No logger is installed;
the host must not log secret-bearing values it explicitly reads from contracts.

## Replay and idempotency

- GET, HEAD and OPTIONS replay automatically, once at most.
- Other methods require `allowMutationReplay: true` AND a nonempty host-provided
  `idempotencyKey`; the client sends it as `Idempotency-Key` on both attempts.
- The host must ensure the backend honors that key. A key is not proof that an
  operation is idempotent; the package cannot guarantee backend deduplication.
- A non-replayable rejected request may successfully refresh the session, then
  returns `replayDenied` without resending its operation.
- No streaming replay, exponential backoff or proactive expiry checks. Buffered
  multipart mutations follow the same explicit idempotency/replay policy.

## Session lifecycle and callback-only logout

Use `session.replaceCredentials` for login and `session.clearCredentials` for
explicit logout. Never mutate the store out-of-band after session construction.
Both APIs fence old work immediately and serialize persistence. Replacement is
usable only after its write succeeds. Session generation and token revision fence
late responses and refresh results: stale successful responses are not delivered,
old refresh cannot resurrect credentials, and old failure cannot clear a new login.

A refresh that fails for a temporary reason (no connection, timeout, cancellation,
HTTP 429 or 5xx — see `isTransientRefreshFailure`) keeps the session and its tokens;
the request fails with that reason and the next rejection refreshes again.

A refused refresh (any other failure), malformed refresh results, save failure, missing credentials and
terminal auth rejection invalidate the affected generation. Clear and unauthorized
notification occur once across concurrent failures; protected calls remain closed
until successful explicit replacement, even if clearing storage fails. Notification
still occurs on clear failure; callback failures are attached as secondary failures.
Explicit `clearCredentials` does not itself send an unauthorized notification.

`UnauthorizedEvent.generation` identifies the failed generation. The host must
compare it with `session.generation` before changing its current auth BLoC or
navigation, especially when a delayed callback overlaps a newer login. Callbacks
run outside the storage queue. Avoid synchronously awaiting a protected request
against the same closed session inside its own callback; finish the callback first.
The package clears credentials only, never unrelated databases/preferences.

## Cancellation and transport ownership

Pass a `NetworkCancellation` and call `cancel()` to cancel that request. Cancelling
one refresh waiter never cancels the shared refresh or another request. Cancelled
requests are not replayed or delivered; the dedicated Dio receives cancellation
for active HTTP operations. Cancellation of an HTTP mutation cannot undo effects
already performed by the server.

Dio supports configurable connect/send/receive timeouts and non-auth
`defaultHeaders`. Authentication must be request-local, never in defaultHeaders;
Authorization is rejected globally. Include any custom auth names in
`authHeaderNames` when constructing the transport to reject them globally too.
The transport is not a general-purpose credential router across multiple origins.

`DioNetworkTransport.close()` stops future sends and closes its own HTTP adapter.
If a host injects an adapter, the host owns its lifetime and must close it after
all operations finish. A custom NetworkTransport likewise remains host-owned.

## Verification

Deterministic tests use test-local stores, refreshers, raw transports and a Dio
HttpClientAdapter. They make no live API calls and assume no backend schema.
Run from the member directory: `flutter test --no-pub` after root workspace
`flutter pub get`. Root app integration and real backend/device verification are
outside this package-only scope.
