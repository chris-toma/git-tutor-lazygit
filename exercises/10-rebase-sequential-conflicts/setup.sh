#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/../../workspace/exercise-10"

echo "============================================"
echo "  Exercise 10: Rebase with Sequential"
echo "              Conflicts"
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

// Complete marks the task as done.
func (t *Task) Complete() {
	t.Done = true
}

// String returns a basic string representation.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}

// TaskList holds a collection of tasks.
type TaskList struct {
	Tasks []Task
	Name  string
}

// NewTaskList creates an empty task list.
func NewTaskList(name string) *TaskList {
	return &TaskList{Name: name}
}

// Add appends a task to the list.
func (tl *TaskList) Add(t Task) {
	tl.Tasks = append(tl.Tasks, t)
}

// Count returns the number of tasks.
func (tl *TaskList) Count() int {
	return len(tl.Tasks)
}
GOFILE

cat > main.go << 'GOFILE'
package main

import (
	"fmt"
	"taskmanager/task"
)

func main() {
	fmt.Println("TaskManager v1.0.0")
	list := task.NewTaskList("My Tasks")
	list.Add(task.NewTask(1, "Learn git"))
	fmt.Printf("%s: %d tasks\n", list.Name, list.Count())
}
GOFILE

git add .
git commit -m "initial commit: task manager with TaskList"

# Create feature branch from initial commit
git checkout -b feature/task-operations

# Now advance main with a change to the core logic area
git checkout main

cat > task/task.go << 'GOFILE'
package task

import (
	"fmt"
	"time"
)

// Task represents a single task.
type Task struct {
	ID        int
	Title     string
	Done      bool
	Priority  int
	UpdatedAt time.Time
}

// NewTask creates a new task.
func NewTask(id int, title string) Task {
	return Task{ID: id, Title: title, UpdatedAt: time.Now()}
}

// Complete marks the task as done and updates the timestamp.
func (t *Task) Complete() {
	t.Done = true
	t.UpdatedAt = time.Now()
}

// SetPriority updates the task priority and timestamp.
func (t *Task) SetPriority(p int) {
	t.Priority = p
	t.UpdatedAt = time.Now()
}

// String returns a detailed string representation.
func (t Task) String() string {
	status := "PENDING"
	if t.Done {
		status = "DONE"
	}
	return fmt.Sprintf("[%s] #%d (P%d): %s (updated: %s)",
		status, t.ID, t.Priority, t.Title,
		t.UpdatedAt.Format("2006-01-02 15:04"))
}

// TaskList holds a collection of tasks.
type TaskList struct {
	Tasks     []Task
	Name      string
	UpdatedAt time.Time
}

// NewTaskList creates an empty task list.
func NewTaskList(name string) *TaskList {
	return &TaskList{Name: name, UpdatedAt: time.Now()}
}

// Add appends a task to the list and updates the timestamp.
func (tl *TaskList) Add(t Task) {
	tl.Tasks = append(tl.Tasks, t)
	tl.UpdatedAt = time.Now()
}

// Count returns the number of tasks.
func (tl *TaskList) Count() int {
	return len(tl.Tasks)
}

// Summary returns a summary string for the list.
func (tl *TaskList) Summary() string {
	done := 0
	for _, t := range tl.Tasks {
		if t.Done {
			done++
		}
	}
	return fmt.Sprintf("%s: %d/%d tasks complete", tl.Name, done, len(tl.Tasks))
}
GOFILE

git add .
git commit -m "add timestamps and priority to core task logic"

# Switch to feature branch and create 3 commits that each build on the same area
git checkout feature/task-operations

# Feature commit 1: add Remove method to TaskList
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

// Complete marks the task as done.
func (t *Task) Complete() {
	t.Done = true
}

// String returns a basic string representation.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}

// TaskList holds a collection of tasks.
type TaskList struct {
	Tasks []Task
	Name  string
}

// NewTaskList creates an empty task list.
func NewTaskList(name string) *TaskList {
	return &TaskList{Name: name}
}

// Add appends a task to the list.
func (tl *TaskList) Add(t Task) {
	tl.Tasks = append(tl.Tasks, t)
}

// Remove deletes a task by ID. Returns true if the task was found and removed.
func (tl *TaskList) Remove(id int) bool {
	for i, t := range tl.Tasks {
		if t.ID == id {
			tl.Tasks = append(tl.Tasks[:i], tl.Tasks[i+1:]...)
			return true
		}
	}
	return false
}

// Count returns the number of tasks.
func (tl *TaskList) Count() int {
	return len(tl.Tasks)
}
GOFILE

git add .
git commit -m "add Remove method to TaskList"

# Feature commit 2: add FindByID and Update methods
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

// Complete marks the task as done.
func (t *Task) Complete() {
	t.Done = true
}

// Rename changes the task title.
func (t *Task) Rename(newTitle string) {
	t.Title = newTitle
}

// String returns a basic string representation.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}

// TaskList holds a collection of tasks.
type TaskList struct {
	Tasks []Task
	Name  string
}

// NewTaskList creates an empty task list.
func NewTaskList(name string) *TaskList {
	return &TaskList{Name: name}
}

// Add appends a task to the list.
func (tl *TaskList) Add(t Task) {
	tl.Tasks = append(tl.Tasks, t)
}

// Remove deletes a task by ID. Returns true if the task was found and removed.
func (tl *TaskList) Remove(id int) bool {
	for i, t := range tl.Tasks {
		if t.ID == id {
			tl.Tasks = append(tl.Tasks[:i], tl.Tasks[i+1:]...)
			return true
		}
	}
	return false
}

// FindByID returns a pointer to the task with the given ID, or nil.
func (tl *TaskList) FindByID(id int) *Task {
	for i := range tl.Tasks {
		if tl.Tasks[i].ID == id {
			return &tl.Tasks[i]
		}
	}
	return nil
}

// Update modifies a task in place using the provided function.
func (tl *TaskList) Update(id int, fn func(*Task)) bool {
	t := tl.FindByID(id)
	if t == nil {
		return false
	}
	fn(t)
	return true
}

// Count returns the number of tasks.
func (tl *TaskList) Count() int {
	return len(tl.Tasks)
}
GOFILE

git add .
git commit -m "add FindByID, Update, and Rename methods"

# Feature commit 3: add filtering methods
cat > task/task.go << 'GOFILE'
package task

import (
	"fmt"
	"strings"
)

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

// Complete marks the task as done.
func (t *Task) Complete() {
	t.Done = true
}

// Rename changes the task title.
func (t *Task) Rename(newTitle string) {
	t.Title = newTitle
}

// String returns a basic string representation.
func (t Task) String() string {
	status := "[ ]"
	if t.Done {
		status = "[x]"
	}
	return fmt.Sprintf("%s #%d: %s", status, t.ID, t.Title)
}

// TaskList holds a collection of tasks.
type TaskList struct {
	Tasks []Task
	Name  string
}

// NewTaskList creates an empty task list.
func NewTaskList(name string) *TaskList {
	return &TaskList{Name: name}
}

// Add appends a task to the list.
func (tl *TaskList) Add(t Task) {
	tl.Tasks = append(tl.Tasks, t)
}

// Remove deletes a task by ID. Returns true if the task was found and removed.
func (tl *TaskList) Remove(id int) bool {
	for i, t := range tl.Tasks {
		if t.ID == id {
			tl.Tasks = append(tl.Tasks[:i], tl.Tasks[i+1:]...)
			return true
		}
	}
	return false
}

// FindByID returns a pointer to the task with the given ID, or nil.
func (tl *TaskList) FindByID(id int) *Task {
	for i := range tl.Tasks {
		if tl.Tasks[i].ID == id {
			return &tl.Tasks[i]
		}
	}
	return nil
}

// Update modifies a task in place using the provided function.
func (tl *TaskList) Update(id int, fn func(*Task)) bool {
	t := tl.FindByID(id)
	if t == nil {
		return false
	}
	fn(t)
	return true
}

// Filter returns a new TaskList with only the tasks matching the predicate.
func (tl *TaskList) Filter(predicate func(Task) bool) *TaskList {
	result := NewTaskList(tl.Name + " (filtered)")
	for _, t := range tl.Tasks {
		if predicate(t) {
			result.Add(t)
		}
	}
	return result
}

// Search returns tasks whose title contains the query (case-insensitive).
func (tl *TaskList) Search(query string) *TaskList {
	query = strings.ToLower(query)
	return tl.Filter(func(t Task) bool {
		return strings.Contains(strings.ToLower(t.Title), query)
	})
}

// Pending returns a list of incomplete tasks.
func (tl *TaskList) Pending() *TaskList {
	return tl.Filter(func(t Task) bool {
		return !t.Done
	})
}

// Count returns the number of tasks.
func (tl *TaskList) Count() int {
	return len(tl.Tasks)
}
GOFILE

git add .
git commit -m "add Filter, Search, and Pending methods"

# Start rebase onto main
git rebase main || true

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "A rebase with sequential conflicts has been created."
echo ""
echo "Main added timestamps and priority to the core task code."
echo "Feature branch has 3 commits that each build on that same code:"
echo "  1. Add Remove method"
echo "  2. Add FindByID, Update, Rename methods"
echo "  3. Add Filter, Search, Pending methods"
echo ""
echo "Rebasing produces a conflict at EACH commit replay because"
echo "each commit was based on the old version of task.go."
echo ""
echo "You must: resolve -> continue -> resolve -> continue -> resolve -> continue"
echo ""
echo "Remember: during rebase, ours=main, theirs=your feature commits."
echo ""
echo "Next steps:"
echo "  1. cd $WORKSPACE"
echo "  2. lazygit"
echo "  3. Follow the instructions in exercises/10-rebase-sequential-conflicts/README.md"
echo ""
