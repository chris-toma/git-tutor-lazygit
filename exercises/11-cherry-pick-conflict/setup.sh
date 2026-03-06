#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-11"

echo "============================================"
echo "  Exercise 11: Cherry-Pick Conflict"
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

mkdir -p task
mkdir -p logging

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

// NewTask creates a new task.
func NewTask(id int, title string) Task {
	return Task{ID: id, Title: title}
}

// String returns a formatted string.
func (t Task) String() string {
	return fmt.Sprintf("#%d: %s", t.ID, t.Title)
}
GOFILE

cat > logging/logger.go << 'GOFILE'
package logging

import (
	"fmt"
	"os"
	"time"
)

// Level represents the severity of a log message.
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

// String returns the string representation of a log level.
func (l Level) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// Logger provides structured logging functionality.
type Logger struct {
	MinLevel Level
	Output   *os.File
}

// New creates a new Logger with the given minimum level.
func New(minLevel Level) *Logger {
	return &Logger{
		MinLevel: minLevel,
		Output:   os.Stdout,
	}
}

// log writes a formatted log entry if the level meets the minimum threshold.
func (l *Logger) log(level Level, msg string) {
	if level < l.MinLevel {
		return
	}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Fprintf(l.Output, "[%s] %s: %s\n", timestamp, level, msg)
}

// Debug logs a debug message.
func (l *Logger) Debug(msg string) {
	l.log(DEBUG, msg)
}

// Info logs an informational message.
func (l *Logger) Info(msg string) {
	l.log(INFO, msg)
}

// Warn logs a warning message.
func (l *Logger) Warn(msg string) {
	l.log(WARN, msg)
}

// Error logs an error message.
func (l *Logger) Error(msg string) {
	l.log(ERROR, msg)
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/logging"
	"taskmanager/task"
)

func main() {
	logger := logging.New(logging.INFO)
	logger.Info("TaskManager starting")

	if len(os.Args) < 2 {
		fmt.Println("TaskManager v1.0.0")
		os.Exit(0)
	}

	t := task.NewTask(1, "Example")
	fmt.Println(t)
}
GOFILE

git add .
git commit -m "initial commit: base task manager with structured logger"

# Create feature/logging branch with 4 incremental commits
git checkout -b feature/logging

# Commit 1: add request logging (modifies the area around Error method)
cat > logging/logger.go << 'GOFILE'
package logging

import (
	"fmt"
	"os"
	"time"
)

// Level represents the severity of a log message.
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

// String returns the string representation of a log level.
func (l Level) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// Logger provides structured logging functionality.
type Logger struct {
	MinLevel  Level
	Output    *os.File
	Component string
}

// New creates a new Logger with the given minimum level.
func New(minLevel Level) *Logger {
	return &Logger{
		MinLevel:  minLevel,
		Output:    os.Stdout,
		Component: "app",
	}
}

// WithComponent creates a child logger with a component name.
func (l *Logger) WithComponent(name string) *Logger {
	return &Logger{
		MinLevel:  l.MinLevel,
		Output:    l.Output,
		Component: name,
	}
}

// log writes a formatted log entry if the level meets the minimum threshold.
func (l *Logger) log(level Level, msg string) {
	if level < l.MinLevel {
		return
	}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Fprintf(l.Output, "[%s] %s [%s]: %s\n", timestamp, level, l.Component, msg)
}

// Debug logs a debug message.
func (l *Logger) Debug(msg string) {
	l.log(DEBUG, msg)
}

// Info logs an informational message.
func (l *Logger) Info(msg string) {
	l.log(INFO, msg)
}

// Warn logs a warning message.
func (l *Logger) Warn(msg string) {
	l.log(WARN, msg)
}

// Error logs an error message.
func (l *Logger) Error(msg string) {
	l.log(ERROR, msg)
}

// LogRequest logs a command request with its arguments.
func (l *Logger) LogRequest(command string, args []string) {
	l.Info(fmt.Sprintf("request: command=%s args=%v", command, args))
}

// LogResponse logs the result of a command execution.
func (l *Logger) LogResponse(command string, success bool, duration time.Duration) {
	if success {
		l.Info(fmt.Sprintf("response: command=%s status=ok duration=%v", command, duration))
	} else {
		l.Warn(fmt.Sprintf("response: command=%s status=fail duration=%v", command, duration))
	}
}
GOFILE

git add .
git commit -m "add component-based logging and request tracking"

# Commit 2: add error context logging (modifies Error method and area around it)
cat > logging/logger.go << 'GOFILE'
package logging

import (
	"fmt"
	"os"
	"runtime"
	"time"
)

// Level represents the severity of a log message.
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

// String returns the string representation of a log level.
func (l Level) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// Logger provides structured logging functionality.
type Logger struct {
	MinLevel  Level
	Output    *os.File
	Component string
}

// New creates a new Logger with the given minimum level.
func New(minLevel Level) *Logger {
	return &Logger{
		MinLevel:  minLevel,
		Output:    os.Stdout,
		Component: "app",
	}
}

// WithComponent creates a child logger with a component name.
func (l *Logger) WithComponent(name string) *Logger {
	return &Logger{
		MinLevel:  l.MinLevel,
		Output:    l.Output,
		Component: name,
	}
}

// log writes a formatted log entry if the level meets the minimum threshold.
func (l *Logger) log(level Level, msg string) {
	if level < l.MinLevel {
		return
	}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Fprintf(l.Output, "[%s] %s [%s]: %s\n", timestamp, level, l.Component, msg)
}

// Debug logs a debug message.
func (l *Logger) Debug(msg string) {
	l.log(DEBUG, msg)
}

// Info logs an informational message.
func (l *Logger) Info(msg string) {
	l.log(INFO, msg)
}

// Warn logs a warning message.
func (l *Logger) Warn(msg string) {
	l.log(WARN, msg)
}

// Error logs an error message.
func (l *Logger) Error(msg string) {
	l.log(ERROR, msg)
}

// ErrorWithContext logs an error with additional context and caller info.
func (l *Logger) ErrorWithContext(err error, context string) {
	if err == nil {
		return
	}
	_, file, line, ok := runtime.Caller(1)
	if ok {
		l.log(ERROR, fmt.Sprintf("%s: %v (at %s:%d)", context, err, file, line))
	} else {
		l.log(ERROR, fmt.Sprintf("%s: %v", context, err))
	}
}

// Fatal logs an error and exits the program.
func (l *Logger) Fatal(err error, context string) {
	l.ErrorWithContext(err, context)
	os.Exit(1)
}

// LogRequest logs a command request with its arguments.
func (l *Logger) LogRequest(command string, args []string) {
	l.Info(fmt.Sprintf("request: command=%s args=%v", command, args))
}

// LogResponse logs the result of a command execution.
func (l *Logger) LogResponse(command string, success bool, duration time.Duration) {
	if success {
		l.Info(fmt.Sprintf("response: command=%s status=ok duration=%v", command, duration))
	} else {
		l.Warn(fmt.Sprintf("response: command=%s status=fail duration=%v", command, duration))
	}
}
GOFILE

git add .
git commit -m "add error context logging with caller info"

# Save the SHA of the error context logging commit for cherry-picking
ERROR_LOG_SHA=$(git rev-parse HEAD)

# Commit 3: add log filtering
cat > logging/logger.go << 'GOFILE'
package logging

import (
	"fmt"
	"os"
	"runtime"
	"strings"
	"time"
)

// Level represents the severity of a log message.
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

// String returns the string representation of a log level.
func (l Level) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// ParseLevel converts a string to a Level.
func ParseLevel(s string) Level {
	switch strings.ToUpper(s) {
	case "DEBUG":
		return DEBUG
	case "INFO":
		return INFO
	case "WARN":
		return WARN
	case "ERROR":
		return ERROR
	default:
		return INFO
	}
}

// Logger provides structured logging functionality.
type Logger struct {
	MinLevel  Level
	Output    *os.File
	Component string
	Filters   []string
}

// New creates a new Logger with the given minimum level.
func New(minLevel Level) *Logger {
	return &Logger{
		MinLevel:  minLevel,
		Output:    os.Stdout,
		Component: "app",
	}
}

// WithComponent creates a child logger with a component name.
func (l *Logger) WithComponent(name string) *Logger {
	return &Logger{
		MinLevel:  l.MinLevel,
		Output:    l.Output,
		Component: name,
		Filters:   l.Filters,
	}
}

// AddFilter adds a substring filter. Only messages containing
// at least one filter string will be logged.
func (l *Logger) AddFilter(filter string) {
	l.Filters = append(l.Filters, filter)
}

// shouldLog checks if a message passes the filters.
func (l *Logger) shouldLog(msg string) bool {
	if len(l.Filters) == 0 {
		return true
	}
	for _, f := range l.Filters {
		if strings.Contains(msg, f) {
			return true
		}
	}
	return false
}

// log writes a formatted log entry if the level meets the minimum threshold.
func (l *Logger) log(level Level, msg string) {
	if level < l.MinLevel {
		return
	}
	if !l.shouldLog(msg) {
		return
	}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Fprintf(l.Output, "[%s] %s [%s]: %s\n", timestamp, level, l.Component, msg)
}

// Debug logs a debug message.
func (l *Logger) Debug(msg string) {
	l.log(DEBUG, msg)
}

// Info logs an informational message.
func (l *Logger) Info(msg string) {
	l.log(INFO, msg)
}

// Warn logs a warning message.
func (l *Logger) Warn(msg string) {
	l.log(WARN, msg)
}

// Error logs an error message.
func (l *Logger) Error(msg string) {
	l.log(ERROR, msg)
}

// ErrorWithContext logs an error with additional context and caller info.
func (l *Logger) ErrorWithContext(err error, context string) {
	if err == nil {
		return
	}
	_, file, line, ok := runtime.Caller(1)
	if ok {
		l.log(ERROR, fmt.Sprintf("%s: %v (at %s:%d)", context, err, file, line))
	} else {
		l.log(ERROR, fmt.Sprintf("%s: %v", context, err))
	}
}

// Fatal logs an error and exits the program.
func (l *Logger) Fatal(err error, context string) {
	l.ErrorWithContext(err, context)
	os.Exit(1)
}

// LogRequest logs a command request with its arguments.
func (l *Logger) LogRequest(command string, args []string) {
	l.Info(fmt.Sprintf("request: command=%s args=%v", command, args))
}

// LogResponse logs the result of a command execution.
func (l *Logger) LogResponse(command string, success bool, duration time.Duration) {
	if success {
		l.Info(fmt.Sprintf("response: command=%s status=ok duration=%v", command, duration))
	} else {
		l.Warn(fmt.Sprintf("response: command=%s status=fail duration=%v", command, duration))
	}
}
GOFILE

git add .
git commit -m "add log filtering and level parsing"

# Commit 4: add performance logging
cat > logging/logger.go << 'GOFILE'
package logging

import (
	"fmt"
	"os"
	"runtime"
	"strings"
	"sync"
	"time"
)

// Level represents the severity of a log message.
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

// String returns the string representation of a log level.
func (l Level) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// ParseLevel converts a string to a Level.
func ParseLevel(s string) Level {
	switch strings.ToUpper(s) {
	case "DEBUG":
		return DEBUG
	case "INFO":
		return INFO
	case "WARN":
		return WARN
	case "ERROR":
		return ERROR
	default:
		return INFO
	}
}

// PerfMetrics tracks performance data for a named operation.
type PerfMetrics struct {
	Count   int
	TotalMs float64
	MaxMs   float64
}

// Logger provides structured logging functionality.
type Logger struct {
	MinLevel  Level
	Output    *os.File
	Component string
	Filters   []string
	mu        sync.Mutex
	metrics   map[string]*PerfMetrics
}

// New creates a new Logger with the given minimum level.
func New(minLevel Level) *Logger {
	return &Logger{
		MinLevel:  minLevel,
		Output:    os.Stdout,
		Component: "app",
		metrics:   make(map[string]*PerfMetrics),
	}
}

// WithComponent creates a child logger with a component name.
func (l *Logger) WithComponent(name string) *Logger {
	return &Logger{
		MinLevel:  l.MinLevel,
		Output:    l.Output,
		Component: name,
		Filters:   l.Filters,
		metrics:   l.metrics,
	}
}

// AddFilter adds a substring filter. Only messages containing
// at least one filter string will be logged.
func (l *Logger) AddFilter(filter string) {
	l.Filters = append(l.Filters, filter)
}

// shouldLog checks if a message passes the filters.
func (l *Logger) shouldLog(msg string) bool {
	if len(l.Filters) == 0 {
		return true
	}
	for _, f := range l.Filters {
		if strings.Contains(msg, f) {
			return true
		}
	}
	return false
}

// log writes a formatted log entry if the level meets the minimum threshold.
func (l *Logger) log(level Level, msg string) {
	if level < l.MinLevel {
		return
	}
	if !l.shouldLog(msg) {
		return
	}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Fprintf(l.Output, "[%s] %s [%s]: %s\n", timestamp, level, l.Component, msg)
}

// Debug logs a debug message.
func (l *Logger) Debug(msg string) {
	l.log(DEBUG, msg)
}

// Info logs an informational message.
func (l *Logger) Info(msg string) {
	l.log(INFO, msg)
}

// Warn logs a warning message.
func (l *Logger) Warn(msg string) {
	l.log(WARN, msg)
}

// Error logs an error message.
func (l *Logger) Error(msg string) {
	l.log(ERROR, msg)
}

// ErrorWithContext logs an error with additional context and caller info.
func (l *Logger) ErrorWithContext(err error, context string) {
	if err == nil {
		return
	}
	_, file, line, ok := runtime.Caller(1)
	if ok {
		l.log(ERROR, fmt.Sprintf("%s: %v (at %s:%d)", context, err, file, line))
	} else {
		l.log(ERROR, fmt.Sprintf("%s: %v", context, err))
	}
}

// Fatal logs an error and exits the program.
func (l *Logger) Fatal(err error, context string) {
	l.ErrorWithContext(err, context)
	os.Exit(1)
}

// LogRequest logs a command request with its arguments.
func (l *Logger) LogRequest(command string, args []string) {
	l.Info(fmt.Sprintf("request: command=%s args=%v", command, args))
}

// LogResponse logs the result of a command execution.
func (l *Logger) LogResponse(command string, success bool, duration time.Duration) {
	if success {
		l.Info(fmt.Sprintf("response: command=%s status=ok duration=%v", command, duration))
	} else {
		l.Warn(fmt.Sprintf("response: command=%s status=fail duration=%v", command, duration))
	}
}

// StartTimer begins timing a named operation. Returns a function to call when done.
func (l *Logger) StartTimer(operation string) func() {
	start := time.Now()
	l.Debug(fmt.Sprintf("timer start: %s", operation))
	return func() {
		elapsed := time.Since(start)
		ms := float64(elapsed.Nanoseconds()) / 1e6
		l.Debug(fmt.Sprintf("timer end: %s took %.2fms", operation, ms))

		l.mu.Lock()
		defer l.mu.Unlock()
		m, ok := l.metrics[operation]
		if !ok {
			m = &PerfMetrics{}
			l.metrics[operation] = m
		}
		m.Count++
		m.TotalMs += ms
		if ms > m.MaxMs {
			m.MaxMs = ms
		}
	}
}

// PrintMetrics outputs all collected performance metrics.
func (l *Logger) PrintMetrics() {
	l.mu.Lock()
	defer l.mu.Unlock()

	l.Info("=== Performance Metrics ===")
	for name, m := range l.metrics {
		avg := m.TotalMs / float64(m.Count)
		l.Info(fmt.Sprintf("  %s: count=%d avg=%.2fms max=%.2fms",
			name, m.Count, avg, m.MaxMs))
	}
}
GOFILE

git add .
git commit -m "add performance logging with metrics"

# Now create the hotfix branch from main with its own diverged logging
git checkout main
git checkout -b hotfix/quick-logging

# The hotfix branch rewrites the logger significantly - replacing the
# Logger struct with a different design and changing the Error method,
# which will conflict with the cherry-picked commit that modifies
# the same area.
cat > logging/logger.go << 'GOFILE'
package logging

import (
	"fmt"
	"io"
	"os"
	"time"
)

// Level represents the severity of a log message.
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

// String returns the string representation of a log level.
func (l Level) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// Logger provides structured logging functionality.
type Logger struct {
	MinLevel Level
	Output   *os.File
	ErrOut   io.Writer
}

// New creates a new Logger with the given minimum level.
func New(minLevel Level) *Logger {
	return &Logger{
		MinLevel: minLevel,
		Output:   os.Stdout,
		ErrOut:   os.Stderr,
	}
}

// log writes a formatted log entry if the level meets the minimum threshold.
func (l *Logger) log(level Level, msg string) {
	if level < l.MinLevel {
		return
	}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	dest := l.Output
	if level == ERROR {
		fmt.Fprintf(l.ErrOut, "[%s] %s: %s\n", timestamp, level, msg)
		return
	}
	fmt.Fprintf(dest, "[%s] %s: %s\n", timestamp, level, msg)
}

// Debug logs a debug message.
func (l *Logger) Debug(msg string) {
	l.log(DEBUG, msg)
}

// Info logs an informational message.
func (l *Logger) Info(msg string) {
	l.log(INFO, msg)
}

// Warn logs a warning message.
func (l *Logger) Warn(msg string) {
	l.log(WARN, msg)
}

// Error logs an error message to the error output stream.
func (l *Logger) Error(msg string) {
	l.log(ERROR, msg)
}

// Errorf logs a formatted error message to the error output stream.
func (l *Logger) Errorf(format string, args ...interface{}) {
	l.Error(fmt.Sprintf(format, args...))
}

// LogAndReturn logs an error and returns it, useful for one-liners.
func (l *Logger) LogAndReturn(err error, context string) error {
	if err != nil {
		l.Error(fmt.Sprintf("%s: %v", context, err))
	}
	return err
}
GOFILE

git add .
git commit -m "add error output stream and convenience error methods"

# Cherry-pick the error context logging commit from feature/logging
git cherry-pick "$ERROR_LOG_SHA" || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A cherry-pick conflict has been created."
echo ""
echo "Branch feature/logging has 4 commits building up the logger:"
echo "  1. Add component-based logging and request tracking"
echo "  2. Add error context logging with caller info  <-- cherry-picked"
echo "  3. Add log filtering and level parsing"
echo "  4. Add performance logging with metrics"
echo ""
echo "Branch hotfix/quick-logging diverged from main and added its own"
echo "error handling (ErrOut stream, Errorf, LogAndReturn), changing the"
echo "Logger struct and the area around the Error method."
echo ""
echo "The cherry-pick of commit 2 conflicts because it tries to add"
echo "ErrorWithContext and Fatal methods in an area that the hotfix"
echo "branch has already changed differently."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/11-cherry-pick-conflict/README.md"
echo ""
