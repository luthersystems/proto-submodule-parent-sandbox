# Parent Proto Experiment

This repository demonstrates how to structure a parent + submodule protobuf workspace, without requiring Buf Schema Registry (BSR) pushes. This pattern is useful when:

* You want to avoid publishing proto definitions externally.
* You want to support local development across multiple proto modules.
* You need a clean separation between core APIs and submodules.

The main APIs are defined under `api/`.
Submodules live under `submodules/`.
`api/` makes use of the protos defined in `submodules`

We separate into `api` and `submodule` repos

The weather submodule as a valid protobuf setup in its own right. Running `buf generate` from within `submodules/weather` validates this. 

## Submodule Independence

The weather submodule (submodules/weather/) is a fully valid standalone protobuf module. You can run code generation directly from within that directory:

```
cd submodules/weather
buf generate
```

This validates and generates code for just the submodule.
Each submodule can define its own buf.yaml and buf.gen.yaml, allowing for independent development, validation, and code generation.

## Repository structure

```
.
├── api
│   ├── srvpb
│   │   └── v1
│   │       └── worldstate.proto
│   └── worldstatepb
│       └── v1
│           └── worldstate.proto
├── buf.gen.yaml
├── buf.lock
├── buf.yaml
├── common.config.mk
├── common.mk
├── go.mod
├── go.sum
├── Makefile
├── README.md
└── submodules
    └── weather              
        ├── api
        │   └── weatherpb
        │       └── v1
        │           └── weather.proto
        ├── buf.gen.yaml
        ├── buf.lock
        ├── buf.yaml
        ├── common.config.mk
        ├── common.mk
        ├── go.mod
        ├── go.sum
        └── Makefile
```

## Building

```
make
```


## Buf configuration

`buf.yaml` declares workspace and modules


```yaml
version: v2

modules:
  - path: api
    name: buf.build/acme/worldstate

  - path: submodules/weather/api
    name: buf.build/acme/weather

deps:
  - buf.build/googleapis/googleapis
  - buf.build/grpc-ecosystem/grpc-gateway

lint:
  use:
    - STANDARD

breaking:
  use:
    - PACKAGE
```

Declares 2 Buf modules:

`api/` → `worldstate`
`submodules/weather/api/` → `weather`

- These modules are generated and validated independently but share a workspace.
- External deps include Google well-known types and grpc-gateway extensions.

`buf.gen.yaml` controls code generation:

```yaml
version: v2

managed:
  enabled: true

plugins:
  - remote: buf.build/protocolbuffers/go
    out: ./generated
    opt:
      - paths=source_relative

  - remote: buf.build/grpc/go
    out: ./generated
    opt:
      - paths=source_relative

  - remote: buf.build/grpc-ecosystem/openapiv2
    out: ./generated

  - remote: buf.build/grpc-ecosystem/gateway
    out: ./generated
    opt:
      - paths=source_relative

inputs:
  - directory: api
  - directory: submodules/weather/api
```

- Code generation writes all Go code into ./generated/ (not alongside proto files).
- Output paths are source_relative to preserve package structures.
- Multiple plugins run together: protoc-gen-go, protoc-gen-go-grpc, grpc-gateway, OpenAPI v2.

## Path Resolution and Package Structure

### Package structure in proto files

#### `worldstate.proto` — shared message types

Located at:

`api/pb/v1/worldstate.proto`

```
package worldstatepb.v1;
option go_package = "github.com/luthersystems/proto-submodule-parent-sandbox/generated/worldstatepb/v1;v1";
```


→ Package name for protobuf = pb.v1
→ Go package = v1 (files generated to: `./generated/worldstatepb/v1/`)


#### `srvpb/worldstate.proto — service definition

Located at:

`api/srvpb/v1/worldstate.proto`

```
package srvpb.v1;
option go_package = "github.com/luthersystems/proto-submodule-parent-sandbox/generated/srvpb/v1;v1";
import "pb/v1/worldstate.proto";
```

→ Depends on shared message types via import paths above
→ Protoc resolves this import relative to the declared inputs: in buf.gen.yaml (i.e. api/).
→ Generated output: `./api//generated/srvpb/v1/*.pb.go`

#### `weather.proto` — weather submodule

Located at:

`submodules/weather/api/weatherpb/v1/weather.proto`

```
package pb.v1;
option go_package = "github.com/luthersystems/proto-submodule-nested-sandbox/generated/weatherpb/v1;v1";
```

→ Similarly defines its own package weatherpb.v1 
→ Generated output: `.submodules/weather/generated/weatherpb/v1/*.pb.go`

## Using the child module

1. Each submodule defines its own fully qualified option go_package using its own Go module path:

```option go_package = "github.com/luthersystems/proto-submodule-nested-sandbox/generated/weatherpb/v1;weatherpbv1";```

No changes to the child proto files are required by the parent.

2. Clone or vendor the submodule repo into the parent's submodules/ directory:

```
git clone git@github.com:luthersystems/proto-submodule-nested-sandbox.git submodules/weather
```

3. in `go.mod`, use a replace directive so that the parent module can find the generated go code

```
module github.com/luthersystems/proto-submodule-sandbox

go 1.24.3

replace github.com/luthersystems/proto-submodule-nested-sandbox => ./submodules/weather

require (
	github.com/luthersystems/proto-submodule-nested-sandbox v0.0.0-00010101000000-000000000000
	...
)
```

The parent imports submodule protos via standard Buf import paths like import "weatherpb/v1/weather.proto"; — no relative import rewrites required, but generated go code in parent module will be able to resolve the child module using `github.com/luthersystems/proto-submodule-nested-sandbox`.
