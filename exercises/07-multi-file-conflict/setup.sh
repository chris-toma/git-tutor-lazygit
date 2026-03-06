#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-07"

echo "============================================"
echo "  Exercise 07: Multi-File Conflict"
echo "============================================"
echo ""
echo "Setting up workspace..."

rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

git init
git config user.email "learner@example.com"
git config user.name "Git Learner"

cat > go.mod << 'GOMOD'
module taskmanager

go 1.21
GOMOD

mkdir -p config
mkdir -p task

# Base config
cat > config/config.go << 'GOFILE'
package config

import (
	"encoding/json"
	"fmt"
	"os"
)

// Config holds the application configuration.
type Config struct {
	AppName    string `json:"app_name"`
	Version    string `json:"version"`
	MaxTasks   int    `json:"max_tasks"`
	DataDir    string `json:"data_dir"`
	DefaultPri int    `json:"default_priority"`
}

// DefaultConfig returns a Config with sensible default values.
func DefaultConfig() Config {
	return Config{
		AppName:    "TaskManager",
		Version:    "1.0.0",
		MaxTasks:   100,
		DataDir:    "./data",
		DefaultPri: 0,
	}
}

// LoadConfig reads the configuration from a JSON file.
func LoadConfig(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return DefaultConfig(), fmt.Errorf("could not read config: %w", err)
	}

	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return DefaultConfig(), fmt.Errorf("could not parse config: %w", err)
	}

	return cfg, nil
}
GOFILE

# Base task.go
cat > task/task.go << 'GOFILE'
package task

import "fmt"

// Task represents a single task.
type Task struct {
	ID       int
	Title    string
	Done     bool
	Priority int
}

// NewTask creates a new task with defaults.
func NewTask(id int, title string) Task {
	return Task{
		ID:       id,
		Title:    title,
		Done:     false,
		Priority: 0,
	}
}

// Validate checks that the task has valid data.
func (t Task) Validate() error {
	if t.Title == "" {
		return fmt.Errorf("task title cannot be empty")
	}
	if t.ID <= 0 {
		return fmt.Errorf("task ID must be positive")
	}
	return nil
}

// String returns a formatted task string.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}
GOFILE

# Base main.go
cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/config"
	"taskmanager/task"
)

func main() {
	cfg, err := config.LoadConfig("config.json")
	if err != nil {
		fmt.Printf("Warning: %v, using defaults\n", err)
		cfg = config.DefaultConfig()
	}

	fmt.Printf("%s v%s\n", cfg.AppName, cfg.Version)

	if len(os.Args) < 2 {
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	t := task.NewTask(1, "Example task")
	if err := t.Validate(); err != nil {
		fmt.Fprintf(os.Stderr, "Invalid task: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(t)
}
GOFILE

git add .
git commit -m "initial commit: app with JSON config, task package, main"

# Branch A: switch config to YAML
git checkout -b feature/yaml-config

cat > config/config.go << 'GOFILE'
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Config holds the application configuration.
type Config struct {
	AppName    string
	Version    string
	MaxTasks   int
	DataDir    string
	DefaultPri int
	LogLevel   string
	LogFile    string
}

// DefaultConfig returns a Config with sensible default values.
func DefaultConfig() Config {
	return Config{
		AppName:    "TaskManager",
		Version:    "1.0.0",
		MaxTasks:   100,
		DataDir:    "./data",
		DefaultPri: 0,
		LogLevel:   "info",
		LogFile:    "",
	}
}

// LoadConfig reads the configuration from a simple YAML-like file.
// This is a simplified parser that handles "key: value" lines.
func LoadConfig(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return DefaultConfig(), fmt.Errorf("could not read config: %w", err)
	}

	cfg := DefaultConfig()
	lines := strings.Split(string(data), "\n")

	for lineNum, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, ":", 2)
		if len(parts) != 2 {
			return cfg, fmt.Errorf("invalid config at line %d: %s", lineNum+1, line)
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		switch key {
		case "app_name":
			cfg.AppName = value
		case "version":
			cfg.Version = value
		case "max_tasks":
			n, err := strconv.Atoi(value)
			if err != nil {
				return cfg, fmt.Errorf("invalid max_tasks value: %s", value)
			}
			cfg.MaxTasks = n
		case "data_dir":
			cfg.DataDir = value
		case "default_priority":
			n, err := strconv.Atoi(value)
			if err != nil {
				return cfg, fmt.Errorf("invalid default_priority value: %s", value)
			}
			cfg.DefaultPri = n
		case "log_level":
			cfg.LogLevel = value
		case "log_file":
			cfg.LogFile = value
		default:
			fmt.Fprintf(os.Stderr, "Warning: unknown config key at line %d: %s\n", lineNum+1, key)
		}
	}

	return cfg, nil
}
GOFILE

cat > task/task.go << 'GOFILE'
package task

import "fmt"

// Task represents a single task.
type Task struct {
	ID       int
	Title    string
	Done     bool
	Priority int
}

// NewTask creates a new task. Uses the given default priority.
func NewTask(id int, title string, defaultPriority int) Task {
	return Task{
		ID:       id,
		Title:    title,
		Done:     false,
		Priority: defaultPriority,
	}
}

// Validate checks that the task has valid data.
// Uses the maxTasks limit from configuration.
func (t Task) Validate(maxID int) error {
	if t.Title == "" {
		return fmt.Errorf("task title cannot be empty")
	}
	if t.ID <= 0 {
		return fmt.Errorf("task ID must be positive")
	}
	if t.ID > maxID {
		return fmt.Errorf("task ID %d exceeds maximum of %d", t.ID, maxID)
	}
	return nil
}

// String returns a formatted task string.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d (P%d): %s", status, t.ID, t.Priority, t.Title)
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/config"
	"taskmanager/task"
)

func main() {
	cfg, err := config.LoadConfig("config.yaml")
	if err != nil {
		fmt.Printf("Warning: %v, using defaults\n", err)
		cfg = config.DefaultConfig()
	}

	fmt.Printf("%s v%s (log: %s)\n", cfg.AppName, cfg.Version, cfg.LogLevel)

	if len(os.Args) < 2 {
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	t := task.NewTask(1, "Example task", cfg.DefaultPri)
	if err := t.Validate(cfg.MaxTasks); err != nil {
		fmt.Fprintf(os.Stderr, "Invalid task: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(t)
}
GOFILE

git add .
git commit -m "switch to YAML config, update task to use config values"

# Branch B: switch config to environment variables
git checkout main
git checkout -b feature/env-config

cat > config/config.go << 'GOFILE'
package config

import (
	"fmt"
	"os"
	"strconv"
)

// Config holds the application configuration.
type Config struct {
	AppName    string
	Version    string
	MaxTasks   int
	DataDir    string
	DefaultPri int
	Debug      bool
	Port       int
}

// DefaultConfig returns a Config with sensible default values.
func DefaultConfig() Config {
	return Config{
		AppName:    "TaskManager",
		Version:    "1.0.0",
		MaxTasks:   100,
		DataDir:    "./data",
		DefaultPri: 0,
		Debug:      false,
		Port:       8080,
	}
}

// LoadConfig reads configuration from environment variables.
// Each config field maps to a TASKMANAGER_ prefixed env var.
func LoadConfig(_ string) (Config, error) {
	cfg := DefaultConfig()
	var warnings []string

	if v := os.Getenv("TASKMANAGER_APP_NAME"); v != "" {
		cfg.AppName = v
	}
	if v := os.Getenv("TASKMANAGER_VERSION"); v != "" {
		cfg.Version = v
	}
	if v := os.Getenv("TASKMANAGER_MAX_TASKS"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			warnings = append(warnings, fmt.Sprintf("invalid TASKMANAGER_MAX_TASKS: %s", v))
		} else {
			cfg.MaxTasks = n
		}
	}
	if v := os.Getenv("TASKMANAGER_DATA_DIR"); v != "" {
		cfg.DataDir = v
	}
	if v := os.Getenv("TASKMANAGER_DEFAULT_PRIORITY"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			warnings = append(warnings, fmt.Sprintf("invalid TASKMANAGER_DEFAULT_PRIORITY: %s", v))
		} else {
			cfg.DefaultPri = n
		}
	}
	if v := os.Getenv("TASKMANAGER_DEBUG"); v == "true" || v == "1" {
		cfg.Debug = true
	}
	if v := os.Getenv("TASKMANAGER_PORT"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			warnings = append(warnings, fmt.Sprintf("invalid TASKMANAGER_PORT: %s", v))
		} else {
			cfg.Port = n
		}
	}

	if len(warnings) > 0 {
		return cfg, fmt.Errorf("config warnings: %v", warnings)
	}

	return cfg, nil
}
GOFILE

cat > task/task.go << 'GOFILE'
package task

import "fmt"

// Task represents a single task.
type Task struct {
	ID       int
	Title    string
	Done     bool
	Priority int
}

// NewTask creates a new task with environment-driven defaults.
func NewTask(id int, title string, debug bool) Task {
	t := Task{
		ID:       id,
		Title:    title,
		Done:     false,
		Priority: 0,
	}
	if debug {
		fmt.Printf("[DEBUG] Created task: %+v\n", t)
	}
	return t
}

// Validate checks that the task has valid data.
// In debug mode, prints validation details.
func (t Task) Validate(debug bool) error {
	if debug {
		fmt.Printf("[DEBUG] Validating task %d: %s\n", t.ID, t.Title)
	}
	if t.Title == "" {
		return fmt.Errorf("task title cannot be empty")
	}
	if t.ID <= 0 {
		return fmt.Errorf("task ID must be positive")
	}
	return nil
}

// String returns a formatted task string.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s Task-%d: %s", status, t.ID, t.Title)
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/config"
	"taskmanager/task"
)

func main() {
	cfg, err := config.LoadConfig("")
	if err != nil {
		fmt.Printf("Warning: %v\n", err)
	}

	if cfg.Debug {
		fmt.Printf("[DEBUG] Config: %+v\n", cfg)
	}

	fmt.Printf("%s v%s (port: %d)\n", cfg.AppName, cfg.Version, cfg.Port)

	if len(os.Args) < 2 {
		fmt.Println("Usage: taskmanager <command>")
		os.Exit(0)
	}

	t := task.NewTask(1, "Example task", cfg.Debug)
	if err := t.Validate(cfg.Debug); err != nil {
		fmt.Fprintf(os.Stderr, "Invalid task: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(t)
}
GOFILE

git add .
git commit -m "switch to env var config, add debug mode"

# Merge yaml-config into env-config
git merge feature/yaml-config || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "Conflicts have been created across multiple files:"
echo "  - config/config.go (YAML parser vs env var reader)"
echo "  - task/task.go (different function signatures)"
echo "  - main.go (different config loading approaches)"
echo ""
echo "All three files must be resolved consistently."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/07-multi-file-conflict/README.md"
echo ""
