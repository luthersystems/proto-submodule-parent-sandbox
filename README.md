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
├── common.config.mk                        # Add some decription here
├── common.mk                               # Add some decription here
├── go.mod
├── go.sum
├-- Outer
    |
    ├── api
    │   ├── pb
    │   │   └── v1
    │   │       └── worldstate.proto       # Shared message definitions
    │   └── srvpb
    │       └── v1
    │           └── worldstate.proto       # Worldstate gRPC + HTTP API definitions
    ├── buf.gen.yaml                       # Code generation config
    ├── buf.yaml                           # Buf workspace + module config
    ├── Makefile                           # Makefile making use of Luther BuildEnv      
    ├── submodules
    │   └── weather
    │       ├── api
    │       │   └── pb
    │       │       └── v1
    │       │           └── weather.proto  # Weather service definitions
    │       ├── buf.gen.yaml               # Submodule codegen config (optional override)
    │       ├── buf.yaml                   # Submodule module config
    │       ├── go.mod                     # Optional Go module for submodule consumer
    │       └── go.sum

```

## Building

```
cd outer
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
package pb.v1;
option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/worldstatepb/v1;v1";
```


→ Package name for protobuf = pb.v1
→ Go package = v1 (files generated to: ./generated/worldstatepb/v1/)


#### `srvpb/worldstate.proto — service definition

Located at:

`api/srvpb/v1/worldstate.proto`

```
package srvpb.v1;
option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/srvpb/v1;v1";
import "pb/v1/worldstate.proto";
```

→ Depends on shared message types via import paths above
→ Protoc resolves this import relative to the declared inputs: in buf.gen.yaml (i.e. api/).
→ Generated output: ./generated/srvpb/v1/*.pb.go

#### `weather.proto` — weather submodule

Located at:

`submodules/weather/api/weatherpb/v1/weather.proto`

```
package pb.v1;
option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/weatherpb/v1;v1";
```

→ Similarly defines its own package weatherpb.v1 
→ Generated output: ./generated/weatherpb/v1/*.pb.go


## Avoiding Package Name Conflicts

To avoid package name conflicts, it is a good idea to namespace properly. When using a submodule, one or more namespaces may clash e.g. `pb/v1`

We use:
```
opt:
  - paths=source_relative
```

as well as

```
inputs:
  # Specify the root directories containing your .proto files
  - directory: api
  - directory: submodules/weather/api
```

This means:

Generated files follow the same directory structure as the source .proto files.
The path is calculated relative to the inputs: directories defined in buf.gen.yaml.
For example:

Proto file: `submodules/weather/api/pb/v1/weather.proto`
Input root: `submodules/weather/api/`
Generated output: `generated/pb/v1/weather.pb.go`

To control output paths, ensure your proto files are organized to match the desired package structure.

Suppose that rather than `api/worldstatepb/v1/worldstate.proto` we had `api/pb/v1/worldstate.proto`
and rather than `submodules/weather/api/weatherpb/v1/weather.proto` we had `submodules/weather/api/pb/v1/weather.proto`
**So step 1:**

We change `api/pb/v1/worldstate.proto` to `api/worldstatepb/v1/worldstate.proto`

and

`submodules/weather/api/pb/v1/weather.proto` to `submodules/weather/api/weatherpb/v1/weather.proto`

to stop this namespace clash.

**Step 2:**

Update go_package names in proto to match:

`option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/pb/v1;v1";` 

becomes 

`option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/worldstatepb/v1;v1";`

and 

`option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/pb/v1;v1";`

becomes 

`option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/weatherpb/v1;v1";`

**Step 3:**

Update import and package name use. We now use `weatherpb` instead of`pb`:

```
syntax = "proto3";

package worldstatepb.v1;

import "weatherpb/v1/weather.proto";

option go_package = "github.com/luthersystems/proto-submodule-sandbox/outer/generated/worldstatepb/v1;v1";

message WorldState {
  weatherpb.v1.GetWeatherResponse current_weather = 1;
}

```
