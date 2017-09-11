# Style Conventions

## Worse is better

### Simplicity

The design must be simple, both in implementation and interface. It is more important for the implementation to be simple than the interface. Simplicity is the most important consideration in a design.

### Correctness

The design must be correct in all observable aspects. It is slightly better to be simple than correct.

### Consistency

The design must not be overly inconsistent. Consistency can be sacrificed for simplicity in some cases, but it is better to drop those parts of the design that deal with less common circumstances than to introduce either implementation complexity or inconsistency.

### Completeness
The design must cover as many important situations as is practical. All reasonably expected cases should be covered. Completeness can be sacrificed in favor of any other quality. In fact, completeness must sacrificed whenever implementation simplicity is jeopardized. Consistency can be sacrificed to achieve completeness if simplicity is retained; especially worthless is consistency of interface.

## API

Prefer tabs over spaces whenever possible.

REST API endpoints are always plural.

Server error messages that are sent to the client should always be human readable.

POST always returns the new object.

Put as much logic as possible in places other than the API endpoint definitions.

**All input MUST be sanitized immediately in the endpoint function, not within
the resources' methods.**
