# syntax=docker/dockerfile:1

############################
# Build stage
############################
FROM golang:1.24-bookworm AS build

WORKDIR /src

# Download dependencies first (cached unless go.mod/go.sum change)
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

# Build a fully static binary (modernc.org/sqlite is pure Go, so no CGO needed)
COPY . .
ENV CGO_ENABLED=0 GOOS=linux
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags="-s -w" -o /out/eraser ./cmd/eraser

############################
# Runtime stage
############################
FROM alpine:3.20

# ca-certificates: required for outbound TLS (SMTP, SendGrid, Resend)
# tzdata: correct timestamps in history
RUN apk add --no-cache ca-certificates tzdata \
    && adduser -D -u 10001 eraser

WORKDIR /app

# Binary + broker database (brokers.yaml is read relative to the working dir)
COPY --from=build /out/eraser /app/eraser
COPY data /app/data

# All mutable state (config.yaml, history.db, pending_job.json) lives under
# $HOME/.eraser. Pointing HOME at /data lets a single mounted volume persist it.
ENV HOME=/data
# Listen on all interfaces inside the container so it's reachable as host:port.
ENV ERASER_HOST=0.0.0.0

RUN mkdir -p /data/.eraser && chown -R eraser:eraser /data
USER eraser

EXPOSE 8080

ENTRYPOINT ["/app/eraser"]
CMD ["serve", "--port", "8080"]
