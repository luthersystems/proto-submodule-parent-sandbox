module github.com/luthersystems/proto-submodule-sandbox

go 1.24.2

replace github.com/luthersystems/nested-proto-submodule => ./outer/submodules/weather

require (
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.26.3
	github.com/luthersystems/nested-proto-submodule v0.0.0
	google.golang.org/genproto/googleapis/api v0.0.0-20250603155806-513f23925822
	google.golang.org/grpc v1.72.2
	google.golang.org/protobuf v1.36.6
)

require (
	golang.org/x/net v0.37.0 // indirect
	golang.org/x/sys v0.33.0 // indirect
	golang.org/x/text v0.23.0 // indirect
	google.golang.org/genproto v0.0.0-20250404141209-ee84b53bf3d0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20250528174236-200df99c418a // indirect
)
