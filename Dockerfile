ARG TRIVY_VERSION=0.32.1
ARG TRIVY_API_VERSION=0.30.0

# Build stage
FROM golang:1.18.3-alpine3.16 AS buildTrivy
ENV COOS linux
RUN apk add --update --no-cache gcc libc-dev
ADD ./trivy/ /go/src
ADD ./src /go/src
WORKDIR /go/src
RUN go build cmd/trivy/main.go -o trivy


FROM golang:1.18.3-alpine3.16 AS buildTriviApi
ENV COOS linux
ADD ./trivy_api/ /go/src
WORKDIR /go/src
RUN go build cmd/scanner-trivy/main.go -o scanner-trivy


# Final stage
FROM alpine:3.16.0 
RUN adduser -u 10000 -D -g '' scanner scanner

COPY --from=buildTrivy trivy /usr/local/bin/trivy
COPY --from=buildTriviApi scanner-trivy /home/scanner/bin/scanner-trivy

ENV TRIVY_VERSION=${TRIVY_VERSION}
ENV TRIVY_API_VERSION=${TRIVY_API_VERSION}

USER scanner
ENTRYPOINT ["/home/scanner/bin/scanner-trivy"]