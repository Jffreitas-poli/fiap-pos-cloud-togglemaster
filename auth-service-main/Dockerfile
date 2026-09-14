# Build stage
FROM golang:1.21 AS builder

WORKDIR /app

COPY . .

RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o auth-service .

# Final stage
FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/auth-service .

CMD ["./auth-service"]
