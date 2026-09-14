package main

import (
	//"context"
	"crypto/sha1"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"net"
	"net/url"
	"strings"
)

const (
	// Tempo de vida do cache em segundos
	CACHE_TTL = 30 * time.Second
)

// getDecision é o wrapper principal
func (a *App) getDecision(userID, flagName string) (bool, error) {
	// 1. Obter os dados da flag (do cache ou dos serviços)
	info, err := a.getCombinedFlagInfo(flagName)
	if err != nil {
		return false, err
	}

	// 2. Executar a lógica de avaliação
	return a.runEvaluationLogic(info, userID), nil
}

// getCombinedFlagInfo busca os dados no Redis, com fallback para os microsserviços
func (a *App) getCombinedFlagInfo(flagName string) (*CombinedFlagInfo, error) {
	cacheKey := fmt.Sprintf("flag_info:%s", flagName)

	// 1. Tentar buscar do Cache (Redis)
	val, err := a.RedisClient.Get(ctx, cacheKey).Result()
	if err == nil {
		// Cache HIT
		var info CombinedFlagInfo
		if err := json.Unmarshal([]byte(val), &info); err == nil {
			log.Printf("Cache HIT para flag '%s'", flagName)
			return &info, nil
		}
		// Se o unmarshal falhar, trata como cache miss
		log.Printf("Erro ao desserializar cache para flag '%s': %v", flagName, err)
	}

	log.Printf("Cache MISS para flag '%s'", flagName)
	// 2. Cache MISS - Buscar dos serviços
	info, err := a.fetchFromServices(flagName)
	if err != nil {
		return nil, err
	}

	// 3. Salvar no Cache
	jsonData, err := json.Marshal(info)
	if err == nil {
		if err := a.RedisClient.Set(ctx, cacheKey, jsonData, CACHE_TTL).Err(); err != nil {
			log.Printf("Falha na gravação do cache redis")
		}
	}

	return info, nil
}

// fetchFromServices busca dados do flag-service e targeting-service concorrentemente
func (a *App) fetchFromServices(flagName string) (*CombinedFlagInfo, error) {
	var wg sync.WaitGroup
	wg.Add(2)

	var flagInfo *Flag
	var ruleInfo *TargetingRule
	var flagErr, ruleErr error

	// Goroutine 1: Buscar do flag-service
	go func() {
		defer wg.Done()
		flagInfo, flagErr = a.fetchFlag(flagName)
	}()

	// Goroutine 2: Buscar do targeting-service
	go func() {
		defer wg.Done()
		ruleInfo, ruleErr = a.fetchRule(flagName)
	}()

	wg.Wait()

	if flagErr != nil {
		return nil, flagErr
	}
	if ruleErr != nil {
		log.Printf("Aviso: Nenhuma regra de segmentação encontrada para '%s'. Usando padrão.", flagName)
	}

	return &CombinedFlagInfo{
		Flag: flagInfo,
		Rule: ruleInfo,
	}, nil
}

// fetchFlag (função helper)
func (a *App) fetchFlag(flagName string) (*Flag, error) {
	url := fmt.Sprintf("%s/flags/%s", a.FlagServiceURL, flagName)

	apiKey := os.Getenv("SERVICE_API_KEY")

	// Define allowed hosts (or pass nil if scanning arbitrary public domains)
	allowedDomains := []string{}

	// Validate and sanitize the input URL string
	safeURL, err := ValidateAndSanitizeURL(url, allowedDomains)
	if err != nil {
		// Handle invalid/unsafe URL error appropriately
		return nil, fmt.Errorf("URL validation failed: %w", err)
	}

	// Pass safeURL.String() or safeURL to http.NewRequest
	// #nosec G704 -- URL is validated by ValidateAndSanitizeURL prior to request creation
	req, err := http.NewRequest("GET", safeURL.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("URL validation failed: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)

	// #nosec G704 -- URL is validated by ValidateAndSanitizeURL prior to request creation
	resp, err := a.HttpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("erro ao chamar flag-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName}
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("flag-service retornou status %d", resp.StatusCode)
	}

	body, _ := io.ReadAll(resp.Body)
	var flag Flag
	if err := json.Unmarshal(body, &flag); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do flag-service: %w", err)
	}
	return &flag, nil
}

func (a *App) fetchRule(flagName string) (*TargetingRule, error) {
	url := fmt.Sprintf("%s/rules/%s", a.TargetingServiceURL, flagName)
	apiKey := os.Getenv("SERVICE_API_KEY") // Usa a mesma chave

	// Define allowed hosts (or pass nil if scanning arbitrary public domains)
	allowedDomains := []string{}

	// Validate and sanitize the input URL string
	safeURL, err := ValidateAndSanitizeURL(url, allowedDomains)
	if err != nil {
		// Handle invalid/unsafe URL error appropriately
		return nil, fmt.Errorf("URL validation failed: %w", err)
	}

	// Pass safeURL.String() or safeURL to http.NewRequest
	// #nosec G704 -- URL is validated by ValidateAndSanitizeURL prior to request creation
	req, err := http.NewRequest("GET", safeURL.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("URL validation failed: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)

	// #nosec G704 -- URL is validated by ValidateAndSanitizeURL prior to request creation
	resp, err := a.HttpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("erro ao chamar targeting-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName} // Não é um erro fatal
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("targeting-service retornou status %d", resp.StatusCode)
	}

	body, _ := io.ReadAll(resp.Body)
	var rule TargetingRule
	if err := json.Unmarshal(body, &rule); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do targeting-service: %w", err)
	}
	return &rule, nil
}

// runEvaluationLogic é onde a decisão é tomada
func (a *App) runEvaluationLogic(info *CombinedFlagInfo, userID string) bool {
	if info.Flag == nil || !info.Flag.IsEnabled {
		return false
	}

	if info.Rule == nil || !info.Rule.IsEnabled {
		return true
	}

	// 3. Processa a regra (só temos "PERCENTAGE" por enquanto)
	rule := info.Rule.Rules
	if rule.Type == "PERCENTAGE" {
		// Converte o 'value' (que é interface{}) para float64
		percentage, ok := rule.Value.(float64)
		if !ok {
			log.Printf("Erro: valor da regra de porcentagem não é um número para a flag '%s'", info.Flag.Name)
			return false
		}

		// Calcula o "bucket" do usuário (0-99)
		userBucket := getDeterministicBucket(userID + info.Flag.Name)

		if float64(userBucket) < percentage {
			return true
		}
	}

	return false
}

func getDeterministicBucket(input string) int {
	// Usamos SHA1 (rápido) e pegamos os primeiros 4 bytes
	hasher := sha1.New()
	hasher.Write([]byte(input))
	hash := hasher.Sum(nil)

	// Converte 4 bytes para um uint32
	val := binary.BigEndian.Uint32(hash[:4])

	// Retorna o módulo 100
	return int(val % 100)
}

// ValidateAndSanitizeURL checks if a given URL string is safe against SSRF attacks.
// It enforces HTTP/HTTPS schemes, verifies domain/host whitelist, and prevents internal IP access.
func ValidateAndSanitizeURL(rawURL string, allowedHosts []string) (*url.URL, error) {
	parsedURL, err := url.ParseRequestURI(rawURL)
	if err != nil {
		return nil, fmt.Errorf("invalid URL format: %w", err)
	}

	// 1. Enforce safe schemes only
	scheme := strings.ToLower(parsedURL.Scheme)
	if scheme != "http" && scheme != "https" {
		return nil, fmt.Errorf("unsupported URL scheme: %s", parsedURL.Scheme)
	}

	hostname := parsedURL.Hostname()
	if hostname == "" {
		return nil, fmt.Errorf("URL missing hostname")
	}

	// 2. Validate against host whitelist (if provided)
	if len(allowedHosts) > 0 {
		allowed := false
		for _, host := range allowedHosts {
			if strings.EqualFold(hostname, host) {
				allowed = true
				break
			}
		}
		if !allowed {
			return nil, fmt.Errorf("hostname %s is not in the allowed list", hostname)
		}
	}

	// 3. Prevent loopback and private IP access (SSRF protection)
	ip := net.ParseIP(hostname)
	if ip != nil {
		if ip.IsLoopback() || ip.IsPrivate() || ip.IsUnspecified() || ip.IsLinkLocalUnicast() {
			return nil, fmt.Errorf("access to private or internal IP %s is forbidden", hostname)
		}
	} else {
		// Resolve hostname to IP to prevent DNS rebinding or localhost resolutions
		ips, err := net.LookupIP(hostname)
		if err != nil {
			return nil, fmt.Errorf("failed to resolve host %s: %w", hostname, err)
		}
		for _, resolvedIP := range ips {
			if resolvedIP.IsLoopback() || resolvedIP.IsPrivate() || resolvedIP.IsUnspecified() || resolvedIP.IsLinkLocalUnicast() {
				return nil, fmt.Errorf("hostname %s resolves to internal IP %s", hostname, resolvedIP.String())
			}
		}
	}

	return parsedURL, nil
}
