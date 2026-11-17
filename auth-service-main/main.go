package main

import (
	"context"
	"database/sql"
	"log/slog"
	"net/http"
	"os"
	"os/signal"

	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/joho/godotenv"

	"go.opentelemetry.io/contrib/bridges/otelslog"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

// App struct (para injeção de dependência)
type App struct {
	DB        *sql.DB
	MasterKey string
}

func main() {
	// Carrega o .env para desenvolvimento local. Em produção, isso não fará nada.
	_ = godotenv.Load()

	//Instrumentação OTEL
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	// Initialize OTel and ensure clean flush on pod termination
	otelShutdown, err := setupOTelSDK(ctx)
	if err != nil {
		panic(err)
	}
	defer func() {
		if cerr := otelShutdown(context.Background()); cerr != nil && err == nil {
			err = cerr
		}
	}()

	// Bridge standard slog to OpenTelemetry Logs
	logger := otelslog.NewLogger("auth-service")
	slog.SetDefault(logger)

	// --- Configuração ---
	port := os.Getenv("PORT")
	if port == "" {
		port = "8001" // Porta padrão
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		slog.Error("DATABASE_URL deve ser definida")
	}

	masterKey := os.Getenv("MASTER_KEY")
	if masterKey == "" {
		slog.Error("MASTER_KEY deve ser definida")
	}

	// --- Conexão com o Banco ---
	db, err := connectDB(databaseURL)
	if err != nil {
		slog.Error("Não foi possível conectar ao banco de dados.", "Erro", err.Error())
	}
	defer func() {
		if cerr := db.Close(); cerr != nil && err == nil {
			err = cerr
		}
	}()

	app := &App{
		DB:        db,
		MasterKey: masterKey,
	}

	// --- Rotas da API ---
	mux := http.NewServeMux()
	mux.HandleFunc("/health", app.healthHandler)

	// Endpoint público para validar uma chave
	mux.HandleFunc("/validate", app.validateKeyHandler)

	// Endpoints de "admin" para criar/gerenciar chaves
	// Eles são protegidos pelo middleware de autenticação
	mux.Handle("/admin/keys", app.masterKeyAuthMiddleware(http.HandlerFunc(app.createKeyHandler)))

	// Wrap the router with otelhttp to capture metrics & traces automatically
	handler := otelhttp.NewHandler(mux, "http-server")
	srv := &http.Server{Addr: ":" + port, Handler: handler}

	slog.Error("Serviço de Autenticação (Go) rodando na porta", "", port)
	if err := srv.ListenAndServe(); err != nil {
		slog.Error("", "Erro", err.Error())
	}
}

// connectDB inicializa e testa a conexão com o PostgreSQL
func connectDB(databaseURL string) (*sql.DB, error) {
	// Bridge standard slog to OpenTelemetry Logs
	logger := otelslog.NewLogger("auth-service")
	slog.SetDefault(logger)

	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return nil, err
	}

	if err = db.Ping(); err != nil {
		return nil, err
	}

	slog.Info("Conectado ao PostgreSQL com sucesso!")
	return db, nil
}
