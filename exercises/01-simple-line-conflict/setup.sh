#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-01"

echo "============================================"
echo "  Exercise 01: Simple Line Conflict"
echo "============================================"
echo ""
echo "Setting up workspace..."

# Clean up any existing workspace
rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

# Initialize repo
git init
git config user.email "learner@example.com"
git config user.name "Git Learner"

# Create go.mod
cat > go.mod << 'GOMOD'
module taskmanager

go 1.21
GOMOD

# Create the base main.go
cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"
)

const AppVersion = "1.0.0"
const AppName = "TaskManager"

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("%s v%s\n", AppName, AppVersion)
		fmt.Println("Usage: taskmanager <command> [arguments]")
		fmt.Println("")
		fmt.Println("Commands:")
		fmt.Println("  add <title>    Add a new task")
		fmt.Println("  list           List all tasks")
		fmt.Println("  done <id>      Mark a task as done")
		fmt.Println("  help           Show this help message")
		os.Exit(0)
	}

	command := os.Args[1]
	switch command {
	case "add":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: 'add' requires a task title")
			os.Exit(1)
		}
		fmt.Printf("Added task: %s\n", os.Args[2])
	case "list":
		fmt.Println("No tasks found.")
	case "done":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: 'done' requires a task ID")
			os.Exit(1)
		}
		fmt.Printf("Marked task %s as done.\n", os.Args[2])
	case "help":
		fmt.Printf("%s v%s\n", AppName, AppVersion)
		fmt.Println("A simple task manager CLI application.")
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		os.Exit(1)
	}
}
GOFILE

git add .
git commit -m "initial commit: base task manager app"

# Create branch: feature/update-branding
git checkout -b feature/update-branding

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"
)

const AppVersion = "2.0.0"
const AppName = "TaskManager Pro"

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("%s v%s\n", AppName, AppVersion)
		fmt.Println("Usage: taskmanager <command> [arguments]")
		fmt.Println("")
		fmt.Println("Commands:")
		fmt.Println("  add <title>    Add a new task")
		fmt.Println("  list           List all tasks")
		fmt.Println("  done <id>      Mark a task as done")
		fmt.Println("  help           Show this help message")
		os.Exit(0)
	}

	command := os.Args[1]
	switch command {
	case "add":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: 'add' requires a task title")
			os.Exit(1)
		}
		fmt.Printf("Added task: %s\n", os.Args[2])
	case "list":
		fmt.Println("No tasks found.")
	case "done":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: 'done' requires a task ID")
			os.Exit(1)
		}
		fmt.Printf("Marked task %s as done.\n", os.Args[2])
	case "help":
		fmt.Printf("%s v%s\n", AppName, AppVersion)
		fmt.Println("A simple task manager CLI application.")
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		os.Exit(1)
	}
}
GOFILE

git add .
git commit -m "update branding to TaskManager Pro v2.0.0"

# Go back to main, create the second branch
git checkout main
git checkout -b feature/update-version

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"os"
)

const AppVersion = "1.5.0"
const AppName = "TaskManager Plus"

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("%s v%s\n", AppName, AppVersion)
		fmt.Println("Usage: taskmanager <command> [arguments]")
		fmt.Println("")
		fmt.Println("Commands:")
		fmt.Println("  add <title>    Add a new task")
		fmt.Println("  list           List all tasks")
		fmt.Println("  done <id>      Mark a task as done")
		fmt.Println("  help           Show this help message")
		os.Exit(0)
	}

	command := os.Args[1]
	switch command {
	case "add":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: 'add' requires a task title")
			os.Exit(1)
		}
		fmt.Printf("Added task: %s\n", os.Args[2])
	case "list":
		fmt.Println("No tasks found.")
	case "done":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Error: 'done' requires a task ID")
			os.Exit(1)
		}
		fmt.Printf("Marked task %s as done.\n", os.Args[2])
	case "help":
		fmt.Printf("%s v%s\n", AppName, AppVersion)
		fmt.Println("A simple task manager CLI application.")
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		os.Exit(1)
	}
}
GOFILE

git add .
git commit -m "update version to 1.5.0 and name to TaskManager Plus"

# Switch to the branding branch and merge the version branch into it
git checkout feature/update-branding
git merge feature/update-version || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A merge conflict has been created."
echo "Both branches changed AppVersion and AppName to different values."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/01-simple-line-conflict/README.md"
echo ""
