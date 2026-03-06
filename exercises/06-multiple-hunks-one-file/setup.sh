#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-06"

echo "============================================"
echo "  Exercise 06: Multiple Hunks in One File"
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
mkdir -p cmd

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

cat > cmd/cli.go << 'GOFILE'
package cmd

import (
	"fmt"
	"os"
	"strings"

	"taskmanager/task"
)

// parseArgs processes the command-line arguments and returns
// the command name and any remaining arguments.
func parseArgs(args []string) (string, []string) {
	if len(args) < 2 {
		return "help", nil
	}
	return args[1], args[2:]
}

// printHelp displays the usage information for the task manager.
func printHelp() {
	fmt.Println("TaskManager - A simple task management tool")
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  taskmanager <command> [arguments]")
	fmt.Println("")
	fmt.Println("Commands:")
	fmt.Println("  add <title>    Add a new task")
	fmt.Println("  list           List all tasks")
	fmt.Println("  done <id>      Mark a task as done")
	fmt.Println("  help           Show this help")
}

// printVersion displays the current version of the application.
func printVersion() {
	fmt.Println("TaskManager v1.0.0")
}

// executeCommand runs the specified command with the given arguments.
// It operates on the provided task slice and returns the updated slice.
func executeCommand(command string, args []string, tasks []task.Task) []task.Task {
	switch command {
	case "add":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'add' requires a title")
			return tasks
		}
		title := strings.Join(args, " ")
		newTask := task.NewTask(len(tasks)+1, title)
		tasks = append(tasks, newTask)
		fmt.Printf("Added: %s\n", title)

	case "list":
		if len(tasks) == 0 {
			fmt.Println("No tasks.")
			return tasks
		}
		for _, t := range tasks {
			status := "[ ]"
			if t.Done {
				status = "[x]"
			}
			fmt.Printf("%s #%d: %s\n", status, t.ID, t.Title)
		}

	case "done":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'done' requires a task ID")
			return tasks
		}
		fmt.Printf("Marked task %s as done.\n", args[0])

	case "help":
		printHelp()

	case "version":
		printVersion()

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printHelp()
	}

	return tasks
}

// Run is the main entry point for the CLI. It parses arguments and executes.
func Run() {
	command, args := parseArgs(os.Args)
	tasks := []task.Task{} // In real app, load from storage
	_ = executeCommand(command, args, tasks)
}
GOFILE

cat > main.go << 'GOFILE'
package main

import "taskmanager/cmd"

func main() {
	cmd.Run()
}
GOFILE

git add .
git commit -m "initial commit: CLI with parseArgs, printHelp, executeCommand"

# Branch A: add flag support
git checkout -b feature/flag-support

cat > cmd/cli.go << 'GOFILE'
package cmd

import (
	"fmt"
	"os"
	"strings"

	"taskmanager/task"
)

// Flags holds the parsed command-line flags.
type Flags struct {
	Verbose  bool
	Format   string
	SortBy   string
	Priority int
}

// parseArgs processes the command-line arguments and returns
// the command name, remaining arguments, and parsed flags.
func parseArgs(args []string) (string, []string, Flags) {
	flags := Flags{Format: "text", SortBy: "id"}
	if len(args) < 2 {
		return "help", nil, flags
	}

	var remaining []string
	command := args[1]

	for i := 2; i < len(args); i++ {
		switch args[i] {
		case "--verbose", "-v":
			flags.Verbose = true
		case "--format", "-f":
			if i+1 < len(args) {
				i++
				flags.Format = args[i]
			}
		case "--sort", "-s":
			if i+1 < len(args) {
				i++
				flags.SortBy = args[i]
			}
		case "--priority", "-p":
			if i+1 < len(args) {
				i++
				flags.Priority = parsePriority(args[i])
			}
		default:
			remaining = append(remaining, args[i])
		}
	}

	return command, remaining, flags
}

// parsePriority converts a string priority to an integer.
func parsePriority(s string) int {
	switch strings.ToLower(s) {
	case "low", "1":
		return 1
	case "medium", "med", "2":
		return 2
	case "high", "3":
		return 3
	case "critical", "crit", "4":
		return 4
	default:
		return 0
	}
}

// printHelp displays the usage information for the task manager.
func printHelp() {
	fmt.Println("TaskManager - A simple task management tool")
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  taskmanager <command> [arguments] [flags]")
	fmt.Println("")
	fmt.Println("Commands:")
	fmt.Println("  add <title>    Add a new task")
	fmt.Println("  list           List all tasks")
	fmt.Println("  done <id>      Mark a task as done")
	fmt.Println("  help           Show this help")
	fmt.Println("")
	fmt.Println("Flags:")
	fmt.Println("  --verbose, -v              Show detailed output")
	fmt.Println("  --format, -f <format>      Output format: text, json, csv")
	fmt.Println("  --sort, -s <field>         Sort by: id, title, priority, done")
	fmt.Println("  --priority, -p <level>     Set priority: low, medium, high, critical")
}

// printVersion displays the current version of the application.
func printVersion() {
	fmt.Println("TaskManager v1.1.0")
}

// executeCommand runs the specified command with the given arguments.
// It operates on the provided task slice and returns the updated slice.
func executeCommand(command string, args []string, flags Flags, tasks []task.Task) []task.Task {
	switch command {
	case "add":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'add' requires a title")
			return tasks
		}
		title := strings.Join(args, " ")
		newTask := task.NewTask(len(tasks)+1, title)
		newTask.Priority = flags.Priority
		tasks = append(tasks, newTask)
		if flags.Verbose {
			fmt.Printf("Added task #%d: %s (priority: %d)\n", newTask.ID, title, newTask.Priority)
		} else {
			fmt.Printf("Added: %s\n", title)
		}

	case "list":
		if len(tasks) == 0 {
			fmt.Println("No tasks.")
			return tasks
		}
		if flags.Verbose {
			fmt.Printf("Listing %d tasks (sorted by: %s, format: %s):\n", len(tasks), flags.SortBy, flags.Format)
		}
		for _, t := range tasks {
			status := "[ ]"
			if t.Done {
				status = "[x]"
			}
			fmt.Printf("%s #%d (P%d): %s\n", status, t.ID, t.Priority, t.Title)
		}

	case "done":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'done' requires a task ID")
			return tasks
		}
		fmt.Printf("Marked task %s as done.\n", args[0])

	case "help":
		printHelp()

	case "version":
		printVersion()

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printHelp()
	}

	return tasks
}

// Run is the main entry point for the CLI. It parses arguments and executes.
func Run() {
	command, args, flags := parseArgs(os.Args)
	tasks := []task.Task{} // In real app, load from storage
	_ = executeCommand(command, args, flags, tasks)
}
GOFILE

git add .
git commit -m "add flag parsing support to CLI"

# Branch B: add subcommand support
git checkout main
git checkout -b feature/subcommands

cat > cmd/cli.go << 'GOFILE'
package cmd

import (
	"fmt"
	"os"
	"strings"

	"taskmanager/task"
)

// Subcommand represents a CLI subcommand with its handler.
type Subcommand struct {
	Name        string
	Description string
	Usage       string
}

// Available subcommands for the task manager.
var subcommands = []Subcommand{
	{Name: "add", Description: "Add a new task", Usage: "add <title>"},
	{Name: "list", Description: "List all tasks", Usage: "list [filter]"},
	{Name: "done", Description: "Mark a task as done", Usage: "done <id>"},
	{Name: "remove", Description: "Remove a task", Usage: "remove <id>"},
	{Name: "search", Description: "Search tasks by keyword", Usage: "search <query>"},
	{Name: "help", Description: "Show this help", Usage: "help [command]"},
	{Name: "version", Description: "Show version info", Usage: "version"},
}

// parseArgs processes the command-line arguments and returns
// the subcommand name and any remaining arguments.
func parseArgs(args []string) (string, []string) {
	if len(args) < 2 {
		return "help", nil
	}

	subcmd := strings.ToLower(args[1])

	// Validate subcommand
	valid := false
	for _, sc := range subcommands {
		if sc.Name == subcmd {
			valid = true
			break
		}
	}

	if !valid {
		fmt.Fprintf(os.Stderr, "Unknown subcommand: %s\n", subcmd)
		fmt.Fprintln(os.Stderr, "Run 'taskmanager help' for usage information.")
		return "help", nil
	}

	return subcmd, args[2:]
}

// printHelp displays the usage information for the task manager.
func printHelp() {
	fmt.Println("TaskManager - A simple task management tool")
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  taskmanager <subcommand> [arguments]")
	fmt.Println("")
	fmt.Println("Subcommands:")
	for _, sc := range subcommands {
		fmt.Printf("  %-12s %s\n", sc.Name, sc.Description)
	}
	fmt.Println("")
	fmt.Println("Run 'taskmanager help <subcommand>' for details on a specific subcommand.")
}

// printSubcommandHelp displays help for a specific subcommand.
func printSubcommandHelp(name string) {
	for _, sc := range subcommands {
		if sc.Name == name {
			fmt.Printf("Usage: taskmanager %s\n", sc.Usage)
			fmt.Printf("\n%s\n", sc.Description)
			return
		}
	}
	fmt.Fprintf(os.Stderr, "No help available for: %s\n", name)
}

// printVersion displays the current version of the application.
func printVersion() {
	fmt.Println("TaskManager v1.0.0")
	fmt.Println("Built with subcommand support.")
}

// executeCommand runs the specified subcommand with the given arguments.
// It operates on the provided task slice and returns the updated slice.
func executeCommand(command string, args []string, tasks []task.Task) []task.Task {
	switch command {
	case "add":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'add' requires a title")
			printSubcommandHelp("add")
			return tasks
		}
		title := strings.Join(args, " ")
		newTask := task.NewTask(len(tasks)+1, title)
		tasks = append(tasks, newTask)
		fmt.Printf("Added task #%d: %s\n", newTask.ID, title)

	case "list":
		if len(tasks) == 0 {
			fmt.Println("No tasks found. Use 'taskmanager add <title>' to create one.")
			return tasks
		}
		fmt.Printf("Tasks (%d total):\n", len(tasks))
		for _, t := range tasks {
			status := "[ ]"
			if t.Done {
				status = "[x]"
			}
			fmt.Printf("  %s #%d: %s\n", status, t.ID, t.Title)
		}

	case "done":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'done' requires a task ID")
			printSubcommandHelp("done")
			return tasks
		}
		fmt.Printf("Marked task %s as done.\n", args[0])

	case "remove":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'remove' requires a task ID")
			printSubcommandHelp("remove")
			return tasks
		}
		fmt.Printf("Removed task %s.\n", args[0])

	case "search":
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "Error: 'search' requires a query")
			printSubcommandHelp("search")
			return tasks
		}
		query := strings.Join(args, " ")
		fmt.Printf("Searching for: %s\n", query)

	case "help":
		if len(args) > 0 {
			printSubcommandHelp(args[0])
		} else {
			printHelp()
		}

	case "version":
		printVersion()

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printHelp()
	}

	return tasks
}

// Run is the main entry point for the CLI. It parses arguments and executes.
func Run() {
	command, args := parseArgs(os.Args)
	tasks := []task.Task{} // In real app, load from storage
	_ = executeCommand(command, args, tasks)
}
GOFILE

git add .
git commit -m "add subcommand support with validation and help"

# Merge flag-support into subcommands to create multiple hunks
git merge feature/flag-support || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A conflict with multiple hunks has been created in cmd/cli.go."
echo "Branch A added flag parsing (--verbose, --format, --sort, --priority)."
echo "Branch B added subcommand validation and per-subcommand help."
echo "Both branches modified parseArgs(), printHelp(), and executeCommand()."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/06-multiple-hunks-one-file/README.md"
echo ""
