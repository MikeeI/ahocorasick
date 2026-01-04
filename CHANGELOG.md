# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial Aho-Corasick implementation
  - `Builder` pattern for configuration
  - `ByteClasses` for alphabet compression
  - `NFA` with trie construction and failure links
  - `Automaton` with `Find`, `FindAll`, `IsMatch`, `Count` methods
  - `LeftmostFirst` and `LeftmostLongest` match semantics
  - Comprehensive test suite
  - Benchmarks

### Performance
- Find (64KB haystack): 137 MB/s
- IsMatch (64KB haystack): 73 MB/s

---

## [0.1.0] - TBD

Initial release.
