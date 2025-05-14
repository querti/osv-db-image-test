# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.22.9@sha256:6ec9c3ce36c929ff98c1e82a8b7fb6c79df766d1ad8009844b59d97da9afed43 as builder

ARG TARGETOS
ARG TARGETARCH

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd/main.go cmd/main.go
COPY tools/ tools/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o osv-generator cmd/main.go

# Use ubi-micro as minimal base image to package the manager binary
# See https://catalog.redhat.com/software/containers/ubi9/ubi-micro/615bdf943f6014fa45ae1b58
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.5@sha256:a50731d3397a4ee28583f1699842183d4d24fadcc565c4688487af9ee4e13a44
WORKDIR /
COPY --from=builder /opt/app-root/src/osv-generator .

RUN /osv-generator -destination-dir /data/osv-db -docker-filename docker.nedb -rpm-filename rpm.nedb -days 1

# It is mandatory to set these labels
LABEL name="Konflux Mintmaker OSV database"
LABEL description="Konflux Mintmaker OSV database"
LABEL io.k8s.description="Konflux Mintmaker OSV database"
LABEL io.k8s.display-name="mintmaker-osv-db"
LABEL summary="Konflux Mintmaker OSV database"
LABEL com.redhat.component="mintmaker-osv-db"

USER 65532:65532
