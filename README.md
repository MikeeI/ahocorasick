# ahocorasick

[![Go Reference](https://pkg.go.dev/badge/github.com/coregx/ahocorasick.svg)](https://pkg.go.dev/github.com/coregx/ahocorasick)
[![Tests](https://github.com/coregx/ahocorasick/actions/workflows/ci.yml/badge.svg)](https://github.com/coregx/ahocorasick/actions/workflows/ci.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/coregx/ahocorasick)](https://goreportcard.com/report/github.com/coregx/ahocorasick)

High-performance Aho-Corasick multi-pattern string matching for Go.

## Overview

This library implements the [Aho-Corasick algorithm](https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm) for efficient simultaneous matching of multiple patterns against a single input string. It is designed to achieve performance comparable to Rust's [aho-corasick](https://github.com/BurntSushi/aho-corasick) crate.

## Features

- **NFA-based Automaton**: Efficient trie with failure links for multi-pattern matching
- **Byte Class Compression**: Reduces alphabet from 256 to pattern-specific equivalence classes
- **Multiple Match Semantics**: LeftmostFirst (Perl-compatible), LeftmostLongest (POSIX-compatible)
- **Zero Dependencies**: Pure Go implementation

### Planned

- **Contiguous NFA**: Memory-efficient automaton with ~8 bytes per state average
- **Dense DFA**: Pre-compiled DFA for maximum search throughput
- **SIMD Prefilters**: Teddy algorithm integration for small pattern sets

## Status

**Version**: 0.1.0 (in development)

This library is under active development. The API is not yet stable.

## Installation

```bash
go get github.com/coregx/ahocorasick
```

## Usage

```go
package main

import (
    "fmt"
    "github.com/coregx/ahocorasick"
)

func main() {
    // Build automaton from patterns
    ac, err := ahocorasick.NewBuilder().
        AddStrings([]string{"apple", "maple", "alpha"}).
        Build()
    if err != nil {
        panic(err)
    }

    // Check if any pattern matches
    haystack := []byte("I love apple pie and maple syrup")
    if ac.IsMatch(haystack) {
        fmt.Println("Found a match!")
    }

    // Find first match
    if match := ac.Find(haystack, 0); match != nil {
        fmt.Printf("Pattern %d matched at [%d:%d]\n",
            match.PatternID, match.Start, match.End)
    }

    // Find all non-overlapping matches
    for _, match := range ac.FindAll(haystack, -1) {
        fmt.Printf("Pattern %d: %q\n",
            match.PatternID, haystack[match.Start:match.End])
    }
}
```

## API Reference

### Builder

```go
NewBuilder() *Builder                     // Create new builder
(*Builder) AddPattern([]byte) *Builder    // Add single pattern
(*Builder) AddPatterns([][]byte) *Builder // Add multiple patterns
(*Builder) AddString(string) *Builder     // Add single string pattern
(*Builder) AddStrings([]string) *Builder  // Add multiple string patterns
(*Builder) MatchKind(MatchKind) *Builder  // Set match semantics
(*Builder) Build() (*Automaton, error)    // Build the automaton
```

### Automaton

```go
(*Automaton) Find(haystack []byte, start int) *Match    // Find first match
(*Automaton) FindAt(haystack []byte, start int) *Match  // Find match at exact position
(*Automaton) FindAll(haystack []byte, n int) []Match    // Find all non-overlapping
(*Automaton) FindAllOverlapping(haystack []byte) []Match // Find all including overlaps
(*Automaton) IsMatch(haystack []byte) bool              // Check if any match exists
(*Automaton) Count(haystack []byte) int                 // Count non-overlapping matches
(*Automaton) PatternCount() int                         // Number of patterns
(*Automaton) Pattern(id int) []byte                     // Get pattern by ID
```

### Match Kinds

```go
LeftmostFirst   // Perl-compatible: first pattern in list wins
LeftmostLongest // POSIX-compatible: longest pattern wins
```

## Performance Targets

| Scenario | Go stdlib | ahocorasick | Target Speedup |
|----------|-----------|-------------|----------------|
| 50 patterns, 4KB input | 50µs | 2µs | 25x |
| 500 patterns, 4KB input | 500µs | 5µs | 100x |
| 1000 patterns, 1MB input | 1s | 10ms | 100x |

## Architecture

Based on research from Rust's aho-corasick implementation:

```
Patterns → Trie Construction → Failure Links → Contiguous NFA
                                                     ↓
                                              (optional)
                                                     ↓
                                               Dense DFA
```

**Automaton Types**:
- **Contiguous NFA**: Single allocation, three state encodings (Dense/One/Sparse)
- **Dense DFA**: Pre-computed transitions, O(n) search regardless of pattern count

## Related Projects

- [coregex](https://github.com/coregx/coregex) - High-performance regex engine for Go (uses this library)
- [BurntSushi/aho-corasick](https://github.com/BurntSushi/aho-corasick) - Rust reference implementation

## License

MIT License - see [LICENSE](LICENSE) for details.
