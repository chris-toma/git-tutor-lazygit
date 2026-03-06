#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-05"

echo "============================================"
echo "  Exercise 05: Delete vs Modify Conflict"
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

cat > task/task.go << 'GOFILE'
package task

// Task represents a single task in the task manager.
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
GOFILE

cat > task/store.go << 'GOFILE'
package task

import (
	"fmt"
	"os"
)

// SaveToFile writes the list of tasks to a text file, one task per line.
// Each line contains the task ID, completion status, and title.
func SaveToFile(tasks []Task, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("could not create file %s: %w", filename, err)
	}
	defer file.Close()

	for _, t := range tasks {
		status := "pending"
		if t.Done {
			status = "done"
		}
		_, err := fmt.Fprintf(file, "%d\t%s\t%s\n", t.ID, status, t.Title)
		if err != nil {
			return fmt.Errorf("could not write task %d: %w", t.ID, err)
		}
	}

	return nil
}

// LoadFromFile reads tasks from a text file and returns them.
func LoadFromFile(filename string) ([]Task, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("could not read file %s: %w", filename, err)
	}

	_ = data // placeholder: parse tasks from data
	return nil, nil
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/task"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("TaskManager v1.0.0")
		os.Exit(0)
	}

	tasks := []task.Task{
		task.NewTask(1, "Learn git"),
		task.NewTask(2, "Practice conflicts"),
	}

	switch os.Args[1] {
	case "save":
		err := task.SaveToFile(tasks, "tasks.txt")
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Tasks saved.")
	default:
		fmt.Println("Unknown command")
	}
}
GOFILE

git add .
git commit -m "initial commit: task store with SaveToFile"

# Branch A: delete SaveToFile, replace with SaveToDatabase
git checkout -b feature/database-storage

cat > task/store.go << 'GOFILE'
package task

import (
	"database/sql"
	"fmt"
)

// SaveToDatabase persists the list of tasks to a SQL database.
// It uses an upsert strategy: existing tasks (by ID) are updated,
// new tasks are inserted.
func SaveToDatabase(tasks []Task, db *sql.DB) error {
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("could not begin transaction: %w", err)
	}
	defer tx.Rollback()

	stmt, err := tx.Prepare(`
		INSERT INTO tasks (id, title, done, priority)
		VALUES (?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			title = excluded.title,
			done = excluded.done,
			priority = excluded.priority
	`)
	if err != nil {
		return fmt.Errorf("could not prepare statement: %w", err)
	}
	defer stmt.Close()

	for _, t := range tasks {
		_, err := stmt.Exec(t.ID, t.Title, t.Done, t.Priority)
		if err != nil {
			return fmt.Errorf("could not save task %d: %w", t.ID, err)
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("could not commit transaction: %w", err)
	}

	return nil
}

// LoadFromDatabase reads all tasks from the database.
func LoadFromDatabase(db *sql.DB) ([]Task, error) {
	rows, err := db.Query("SELECT id, title, done, priority FROM tasks ORDER BY id")
	if err != nil {
		return nil, fmt.Errorf("could not query tasks: %w", err)
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var t Task
		if err := rows.Scan(&t.ID, &t.Title, &t.Done, &t.Priority); err != nil {
			return nil, fmt.Errorf("could not scan task: %w", err)
		}
		tasks = append(tasks, t)
	}

	return tasks, rows.Err()
}

// InitDatabase creates the tasks table if it does not exist.
func InitDatabase(db *sql.DB) error {
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS tasks (
			id INTEGER PRIMARY KEY,
			title TEXT NOT NULL,
			done BOOLEAN DEFAULT FALSE,
			priority INTEGER DEFAULT 0
		)
	`)
	if err != nil {
		return fmt.Errorf("could not create tasks table: %w", err)
	}
	return nil
}
GOFILE

# Update main.go to use database
cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("TaskManager v1.1.0 (database backend)")
		os.Exit(0)
	}

	fmt.Println("Database storage enabled. Use 'taskmanager db-save' to persist tasks.")
}
GOFILE

git add .
git commit -m "replace file storage with database storage"

# Branch B: enhance SaveToFile to support JSON and CSV formats
git checkout main
git checkout -b feature/multi-format-export

# Update main.go to use the new format parameter
cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"

	"taskmanager/task"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("TaskManager v1.1.0 (multi-format export)")
		os.Exit(0)
	}

	tasks := []task.Task{
		task.NewTask(1, "Learn git"),
		task.NewTask(2, "Practice conflicts"),
	}

	switch os.Args[1] {
	case "save":
		filename := "tasks.txt"
		format := task.FormatText
		if len(os.Args) > 2 {
			filename = os.Args[2]
		}
		if len(os.Args) > 3 {
			switch os.Args[3] {
			case "json":
				format = task.FormatJSON
			case "csv":
				format = task.FormatCSV
			}
		}
		err := task.SaveToFile(tasks, filename, format)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Tasks saved.")
	default:
		fmt.Println("Unknown command")
	}
}
GOFILE

cat > task/store.go << 'GOFILE'
package task

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

// FileFormat represents the output format for saving tasks.
type FileFormat string

const (
	FormatText FileFormat = "text"
	FormatJSON FileFormat = "json"
	FormatCSV  FileFormat = "csv"
)

// SaveToFile writes the list of tasks to a file in the specified format.
// Supported formats: "text" (tab-separated), "json", "csv".
// If format is empty, it is inferred from the file extension.
func SaveToFile(tasks []Task, filename string, format FileFormat) error {
	if format == "" {
		format = inferFormat(filename)
	}

	switch format {
	case FormatJSON:
		return saveJSON(tasks, filename)
	case FormatCSV:
		return saveCSV(tasks, filename)
	case FormatText:
		return saveText(tasks, filename)
	default:
		return fmt.Errorf("unsupported format: %s", format)
	}
}

// inferFormat guesses the file format from the file extension.
func inferFormat(filename string) FileFormat {
	switch filepath.Ext(filename) {
	case ".json":
		return FormatJSON
	case ".csv":
		return FormatCSV
	default:
		return FormatText
	}
}

// saveJSON writes tasks as a JSON array.
func saveJSON(tasks []Task, filename string) error {
	data, err := json.MarshalIndent(tasks, "", "  ")
	if err != nil {
		return fmt.Errorf("could not marshal JSON: %w", err)
	}
	return os.WriteFile(filename, data, 0644)
}

// saveCSV writes tasks as CSV with headers.
func saveCSV(tasks []Task, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("could not create CSV file: %w", err)
	}
	defer file.Close()

	w := csv.NewWriter(file)
	defer w.Flush()

	// Write header row
	if err := w.Write([]string{"ID", "Title", "Done", "Priority"}); err != nil {
		return fmt.Errorf("could not write CSV header: %w", err)
	}

	for _, t := range tasks {
		record := []string{
			strconv.Itoa(t.ID),
			t.Title,
			strconv.FormatBool(t.Done),
			strconv.Itoa(t.Priority),
		}
		if err := w.Write(record); err != nil {
			return fmt.Errorf("could not write task %d: %w", t.ID, err)
		}
	}

	return nil
}

// saveText writes tasks in the original tab-separated text format.
func saveText(tasks []Task, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("could not create file %s: %w", filename, err)
	}
	defer file.Close()

	for _, t := range tasks {
		status := "pending"
		if t.Done {
			status = "done"
		}
		_, err := fmt.Fprintf(file, "%d\t%s\t%s\n", t.ID, status, t.Title)
		if err != nil {
			return fmt.Errorf("could not write task %d: %w", t.ID, err)
		}
	}

	return nil
}

// LoadFromFile reads tasks from a text file and returns them.
func LoadFromFile(filename string) ([]Task, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("could not read file %s: %w", filename, err)
	}

	_ = data // placeholder: parse tasks from data
	return nil, nil
}
GOFILE

git add .
git commit -m "enhance SaveToFile to support JSON, CSV, and text formats"

# Merge database-storage into multi-format-export
git merge feature/database-storage || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A delete-vs-modify conflict has been created in task/store.go."
echo "Branch A deleted SaveToFile and replaced it with SaveToDatabase."
echo "Branch B enhanced SaveToFile to support multiple file formats."
echo "You need to decide: keep the enhanced file version, the database version, or both."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/05-delete-vs-modify-conflict/README.md"
echo ""
