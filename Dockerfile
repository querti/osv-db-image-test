# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.23.6-1747333074@sha256:e0ad156b08e0b50ad509d79513e13e8a31f2812c66e9c48c98cea53420ec2bca as builder

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
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.5@sha256:b87097994ed62fbf1de70bc75debe8dacf3ea6e00dd577d74503ef66452c59d6
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
