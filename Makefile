SHELL := /bin/sh

CWD := $(shell pwd)
# Overridable via environment: SBCL=/path/to/sbcl QL=/path/to/quicklisp/setup.lisp
SBCL ?= sbcl
QL ?= $(HOME)/quicklisp/setup.lisp

SBCL_FLAGS := --dynamic-space-size 8096 --noinform --disable-debugger --non-interactive
ASDF_BOOT := --eval '(require :asdf)' --eval "(pushnew \#p\"$(CWD)/\" asdf:*central-registry*)"
QL_BOOT := --eval '(load "$(QL)")'

SYSTEM := flutter-render-stack
TEST_SYSTEM := flutter-render-stack/tests
TEST_PKG := flutter-render-stack-tests

.PHONY: all load test test-impeller test-flow test-exports test-conditions \
	test-enums test-integration clean check-quicklisp

all: test

# Load/compile check — verifies system loads without errors
load: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(SYSTEM) :force t :silent t)' \
	  --eval '(format t "~&System loaded successfully.~%")'

check-quicklisp:
	@test -f "$(QL)" || { \
	  echo "Quicklisp not found at $(QL). Override QL=/path/to/quicklisp/setup.lisp"; \
	  exit 1; \
	}

# Run all tests
test: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(SYSTEM) :force t :silent t)' \
	  --eval '(asdf:test-system "$(SYSTEM)")'

# Run individual test suites
test-impeller: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(TEST_SYSTEM) :silent t)' \
	  --eval '(parachute:test (quote $(TEST_PKG)::impeller-suite))'

test-flow: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(TEST_SYSTEM) :silent t)' \
	  --eval '(parachute:test (quote $(TEST_PKG)::flow-suite))'

test-exports: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(TEST_SYSTEM) :silent t)' \
	  --eval '(parachute:test (quote $(TEST_PKG)::export-suite))'

test-conditions: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(TEST_SYSTEM) :silent t)' \
	  --eval '(parachute:test (quote $(TEST_PKG)::condition-suite))'

test-enums: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(TEST_SYSTEM) :silent t)' \
	  --eval '(parachute:test (quote $(TEST_PKG)::enum-suite))'

test-integration: check-quicklisp
	$(SBCL) $(SBCL_FLAGS) $(QL_BOOT) $(ASDF_BOOT) \
	  --eval '(ql:quickload :$(TEST_SYSTEM) :silent t)' \
	  --eval '(parachute:test (quote $(TEST_PKG)::integration-suite))'

clean:
	@find . -type f \( -name "*.fasl" -o -name "*.x86f" -o -name "*.fas" \) -print0 | xargs -0 -r rm -f
