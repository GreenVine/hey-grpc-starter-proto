ARG GO_VERSION=1.15

FROM golang:${GO_VERSION}-alpine AS bootstrapper

RUN apk add --update --no-cache build-base ca-certificates curl git upx \
    && rm -rf /var/cache/apk/*

ENV GOLANG_PROTOBUF_VERSION=1.4.3 \
    GOGO_PROTOBUF_VERSION=1.3.2 \
    GOLANG_VALIDATE_VERSION=0.4.1
RUN GO111MODULE=on go get \
    github.com/envoyproxy/protoc-gen-validate@v${GOLANG_VALIDATE_VERSION} \
    github.com/golang/protobuf/protoc-gen-go@v${GOLANG_PROTOBUF_VERSION} \
    github.com/gogo/protobuf/protoc-gen-gofast@v${GOGO_PROTOBUF_VERSION} \
    github.com/gogo/protobuf/protoc-gen-gogo@v${GOGO_PROTOBUF_VERSION} \
    github.com/gogo/protobuf/protoc-gen-gogofast@v${GOGO_PROTOBUF_VERSION} \
    github.com/gogo/protobuf/protoc-gen-gogofaster@v${GOGO_PROTOBUF_VERSION} \
    github.com/gogo/protobuf/protoc-gen-gogoslick@v${GOGO_PROTOBUF_VERSION} \
    && mv /go/bin/protoc-gen-* /usr/local/bin/

ENV GRPC_GATEWAY_VERSION=2.1.0
RUN curl -sfSL \
    https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v${GRPC_GATEWAY_VERSION}/protoc-gen-grpc-gateway-v${GRPC_GATEWAY_VERSION}-linux-x86_64 \
    -o /usr/local/bin/protoc-gen-grpc-gateway \
    && curl -sfSL \
    https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v${GRPC_GATEWAY_VERSION}/protoc-gen-openapiv2-v${GRPC_GATEWAY_VERSION}-linux-x86_64 \
    -o /usr/local/bin/protoc-gen-openapiv2 \
    && chmod +x /usr/local/bin/protoc-gen-grpc-gateway /usr/local/bin/protoc-gen-openapiv2

ENV GRPC_WEB_VERSION=1.2.1
RUN curl -sfSL \
    https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 \
    -o /usr/local/bin/protoc-gen-grpc-web \
    && chmod +x /usr/local/bin/protoc-gen-grpc-web

ENV YARPC_VERSION=1.49.1
RUN git clone --depth 1 -b v${YARPC_VERSION} https://github.com/yarpc/yarpc-go.git /go/src/go.uber.org/yarpc \
    && cd /go/src/go.uber.org/yarpc \
    && GO111MODULE=on go install ./encoding/protobuf/protoc-gen-yarpc-go \
    && mv /go/bin/protoc-gen-yarpc-go /usr/local/bin/

ENV PROTOBUF_VERSION=3.13.0
RUN mkdir -p /tmp/protoc \
    && curl -sfSL \
    https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip \
    -o /tmp/protoc/protoc.zip \
    && cd /tmp/protoc \
    && unzip protoc.zip \
    && mv /tmp/protoc/include /usr/local/include

ENV PROTOTOOL_VERSION=1.10.0
RUN curl -sfSL \
    https://github.com/uber/prototool/releases/download/v${PROTOTOOL_VERSION}/prototool-Linux-x86_64 \
    -o /usr/local/bin/prototool \
    && chmod +x /usr/local/bin/prototool

ENV MOCKERY_VERSION=2.5.1
RUN mkdir -p /tmp/mockery \
    && curl -sfSL \
    https://github.com/vektra/mockery/releases/download/v${MOCKERY_VERSION}/mockery_${MOCKERY_VERSION}_Linux_x86_64.tar.gz \
    -o /tmp/mockery/mockery.tar.gz \
    && cd /tmp/mockery \
    && tar -zxf mockery.tar.gz \
    && mv /tmp/mockery/mockery /usr/local/bin/mockery \
    && chmod +x /usr/local/bin/mockery

RUN upx --lzma -q /usr/local/bin/*


FROM alpine:latest AS base

WORKDIR /workspace

ENV \
    PROTOTOOL_PROTOC_BIN_PATH=/usr/bin/protoc \
    PROTOTOOL_PROTOC_WKT_PATH=/usr/include

RUN apk add --update --no-cache ca-certificates grpc protobuf \
    && rm -rf /var/cache/apk/*

COPY --from=bootstrapper /usr/local/bin /usr/local/bin
COPY --from=bootstrapper /usr/local/include /usr/include

ENV GOGO_PROTOBUF_VERSION=1.3.2 \
    GOLANG_PROTOBUF_VERSION=1.4.3 \
    GRPC_GATEWAY_VERSION=2.1.0 \
    GRPC_WEB_VERSION=1.2.1 \
    YARPC_VERSION=1.49.1 \
    PROTOTOOL_VERSION=1.10.0 \
    MOCKERY_VERSION=2.5.1 \
    PROTOTOOL_PROTOC_BIN_PATH=/usr/bin/protoc \
    PROTOTOOL_PROTOC_WKT_PATH=/usr/include

ENTRYPOINT ["prototool"]
