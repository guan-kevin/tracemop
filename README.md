# TraceMOP: A Trace-Aware Runtime Verification Tool for Java

This repository allows to do explicit-trace runtime verification, and it is built on top of improved and integrated source code that was forked off the official [JavaMOP](https://github.com/runtimeverification/javamop) and [RV-Monitor](https://github.com/runtimeverification/rv-monitor) repositories. Those repositories are *no longer maintained but we have ensured to preserve all their Java-related functionality here (read on to see how to run TraceMOP to get only those existing functionality)*.

## Prerequisites

We have only tested TraceMOP on:

1. Java 1.8
2. Maven 3.8.8 and above
3. Maven Surefire 2.14 and above
4. Operating System: Ubuntu 20.04.6 LTS

## Setting up

1. [Install Docker](https://docs.docker.com/get-started/get-docker/)

There are two ways to use TraceMOP at this time. In the future, we will add documentation on how to use TraceMOP without Docker.

1. **Use Docker image provided by TraceMOP.** From any directory, run:

   a. `docker pull softengresearch/tracemop`
   
   b. `docker run -it softengresearch/tracemop`

2. **Building your own image from scratch.** From the same directory as this README.md file, run:

   a. `docker build -f scripts/Dockerfile . -t tracemop`

   b. `docker run -it tracemop /bin/bash`

## Using TraceMOP to monitor Maven projects

1. **Run with trace collection.** Run the following commands **inside** Docker container:

   a. `cd ~/tracemop/scripts`

   b. `bash collect_traces.sh <org/repo> <sha> <output-directory> [measure-time (default is false)] [collect-per-test (default is false)]`

   Example: `bash collect_traces.sh flowpowered/commons 0690efd output true`.

   The above example will collect traces for the project, [flowpowered/commons (sha 0690efd)](https://github.com/flowpowered/commons), save results to `output` directory.

2. **Run without trace collection (i.e., only get JavaMOP functionality).** Run the following commands **inside** Docker container:

   a. `cd ~/tracemop/scripts`

   b. `bash not_collect_traces.sh <org/repo> <sha> <output-directory> [statistics (default is false)] [save-violations (default is true)]`

   Example: `bash not_collect_traces.sh flowpowered/commons 0690efd output`

   The above example will run RV on flowpowered/commons (sha 0690efd), save results to `output` directory.

## Output Structure

The output directory contains 4 sub-directories:

| Directory           | Contents                                           |
| --------------------|----------------------------------------------------|
| all-traces          | the recorded traces                                |
| logs                | the outputs of `git clone`, `mvn test`, etc.       |
| project             | the source code of the input project               |
| repo                | maven's m2 repository for the input project        |

(If running with `collect_traces.sh`) The all-traces directory contains 4 files:

| Directory           | Purpose                                             |
| --------------------| ----------------------------------------------------|
| locations.txt       | maps short location IDs to actual line of code      |
| specs-frequency.csv | maps trace IDs to specs and frequencies             |
| specs-test.csv      | maps trace IDs to tests that generated the traces   |
| unique-traces.txt   | list of unique traces (trace ID, frequench, tracce) |

If TraceMOP raised violations during RV, TraceMOP will save the violations to file: `project/violation-counts`

## Configuration

Depending on a project’s characteristics (e.g., when there are very few tests), naively collecting all traces can outperform our new data structures. So, we provide an option to switch to this naive approach:

```bash
export TRACEMOP_DB=simple  // Store traces in simple data structure
export TRACEMOP_DB=trie  // Store traces in new prefix tree like data structure
```

## Contributing

We are accepting issues and pull requests. We welcome all who are interested to help fix issues.



