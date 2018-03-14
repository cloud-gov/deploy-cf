package main

import (
	"log"
	"net/http"
	"os"
	"os/exec"
)

func main() {
	http.HandleFunc("/below-binary", handleBelowBinary)
	log.Fatal(http.ListenAndServe(":"+os.Getenv("PORT"), nil))
}

func handleBelowBinary(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("mkdir", "/bin/groundhog")
	if err := cmd.Run(); err == nil {
		w.WriteHeader(http.StatusInternalServerError)
	}
}
