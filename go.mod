module github.com/luthersystems/proto-submodule-parent-sandbox

go 1.24.3

replace github.com/luthersystems/proto-submodule-nested-sandbox => ./submodules/weather

require (
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.26.3
	github.com/luthersystems/proto-submodule-nested-sandbox v0.0.0-00010101000000-000000000000
	google.golang.org/genproto/googleapis/api v0.0.0-20251202230838-ff82c1b0f217
	google.golang.org/grpc v1.79.3
	google.golang.org/protobuf v1.36.10
)

require (
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto v0.0.0-20250404141209-ee84b53bf3d0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
)
