# Architecture

Last updated: 2026-06-05

Single service. Layered: API (HTTP) -> Service (rules) -> Storage (DB).
Dependency direction is one-way (API -> Service -> Storage); enforce with a structural test.
