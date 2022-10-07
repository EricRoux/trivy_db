ARG TRIVY_VERSION=0.29.2
ARG TRIVY_API_VERSION=0.30.0

# Build stage
FROM golang:1.18.3-alpine3.16 AS buildTriviApi
ENV COOS linux
ADD ./trivy_api/ /go/src
ADD ./src /go/src
WORKDIR /go/src
RUN go build -o scanner-trivy cmd/scanner-trivy/main.go



# Final stage
FROM aquasec/trivy:${TRIVY_VERSION}
RUN adduser -u 10000 -D -g '' scanner scanner
RUN apk add --update --no-cache curl

COPY --from=buildTriviApi /go/src/scanner-trivy /home/scanner/bin/scanner-trivy

ENV TRIVY_VERSION=${TRIVY_VERSION}
ENV TRIVY_API_VERSION=${TRIVY_API_VERSION}

USER scanner
ENTRYPOINT ["/home/scanner/bin/scanner-trivy"]