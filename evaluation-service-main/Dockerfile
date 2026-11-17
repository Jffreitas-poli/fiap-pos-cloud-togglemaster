# Build stage
FROM golang:1.27 AS builder

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o evaluation-service .

# Final stage
FROM scratch

WORKDIR /app

COPY --from=builder /app/evaluation-service .
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

CMD ["./evaluation-service"]
