# Style Conventions

## API

Prefer tabs over spaces whenever possible.

REST API endpoints are always plural.

Server error messages that are sent to the client should always be human readable.

POST always returns the new object.

Put as much logic as possible in places other than the API endpoint definitions.

**All input MUST be sanitized immediately in the endpoint function, not within
the resources' methods.**
