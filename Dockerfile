# Stage 1: Build the Go application
FROM golang:buster AS build

# Set the working directory inside the container
WORKDIR /srv/grpc

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download and cache dependencies
RUN go mod download

# Copy the protobuf file
COPY hello.proto ./protos/

# Copy the server and client source code
COPY server/*.go ./server/
COPY client/*.go ./client/

# Install protoc and protoc-gen-go plugin
ARG VERS="3.11.4"
ARG ARCH="linux-x86_64"
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v${VERS}/protoc-${VERS}-${ARCH}.zip \
    --output-document=./protoc-${VERS}-${ARCH}.zip && \
    apt update && apt install -y unzip && \
    unzip -o protoc-${VERS}-${ARCH}.zip -d protoc-${VERS}-${ARCH} && \
    mv protoc-${VERS}-${ARCH}/bin/* /usr/local/bin && \
    mv protoc-${VERS}-${ARCH}/include/* /usr/local/include && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Generate Golang protobuf files
RUN protoc \
    --proto_path=./protos \
    --go_out=. --go-grpc_out=. \
    ./protos/hello.proto

# Build the server
RUN CGO_ENABLED=0 GOOS=linux \
    go build -a -installsuffix cgo \
    -o /go/bin/server \
    ./server

# Build the client (optional, for testing purposes)
RUN CGO_ENABLED=0 GOOS=linux \
    go build -a -installsuffix cgo \
    -o /go/bin/client \
    ./client

FROM scratch

COPY --from=build /go/bin/server /server
    
ENTRYPOINT ["/server"]
