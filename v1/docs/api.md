# API Reference

## PUT requests

PUT can be used for either whole-document replacement or partial replacement.
This is non-standard, but used to avoid PATCH.

e.g.

```
PUT /api/v1/users/4 HTTP/1.1
...
{
    "name" : "John Doe"
}
```

## Users

User JSON objects look like this:

```
{
    "email": "katie@example.com",
    "id": 3,
    "name": "Katie"
}
```
