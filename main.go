package main

import (
	"crypto/md5"
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"os/exec"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	// 1. Weak cryptographic hash - MD5 usage
	data := "sensitive data"
	hash := md5.Sum([]byte(data))
	fmt.Printf("MD5 Hash: %x\n", hash)

	// 2. SQL injection vulnerability
	username := "admin' OR '1'='1"
	query := fmt.Sprintf("SELECT * FROM users WHERE username = '%s'", username)
	fmt.Println("Query:", query)

	// 3. Command injection vulnerability
	userInput := "file.txt; echo butts"
	cmd := exec.Command("sh", "-c", "cat "+userInput)
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Command failed:", err)
	} else {
		fmt.Println("Output:", string(output))
	}

	// 4. Hardcoded credentials
	dbPassword := "admin123"
	connectionString := fmt.Sprintf("user:admin:password:%s@tcp(localhost:3306)/database", dbPassword)
	db, err := sql.Open("mysql", connectionString)
	if err != nil {
		fmt.Println("DB connection failed:", err)
	}
	defer db.Close()

	// 5. HTTP without TLS
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, %s!", r.URL.Query().Get("name"))
	})

	// 6. Insecure random number generation (if you add crypto/rand import)
	// This would be flagged for using math/rand instead of crypto/rand for security purposes

	// 7. File path traversal vulnerability
	filename := "../../../etc/passwd"
	file, err := os.Open(filename)
	if err != nil {
		fmt.Println("File open failed:", err)
	} else {
		defer file.Close()
		fmt.Println("File opened successfully")
	}

	fmt.Println("Starting HTTP server on port 8080...")
	http.ListenAndServe(":8080", nil)
}
