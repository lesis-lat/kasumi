# Kasumi Architecture - Flow-Based Programming

This document describes the Flow-Based Programming (FBP) architecture of Kasumi.

## Table of Contents

- [Overview](#overview)
- [Flow-Based Programming Concepts](#flow-based-programming-concepts)
- [Component Architecture](#component-architecture)
- [Data Flow](#data-flow)
- [Module Reference](#module-reference)
- [Extending Kasumi](#extending-kasumi)

---

## Overview

Kasumi has been refactored to follow the Flow-Based Programming paradigm, where the application is composed of independent components that communicate through well-defined data flows.

### Key Benefits

- **Modularity**: Each component is independent and reusable
- **Testability**: Components can be tested in isolation
- **Maintainability**: Changes are localized to specific components
- **Scalability**: Easy to add new components or modify flows
- **Clarity**: Data flow is explicit and easy to understand

---

## Flow-Based Programming Concepts

### Components (Processes)

Independent units that perform specific tasks. Each component:
- Has a single, well-defined responsibility
- Receives input data through defined interfaces
- Produces output data for other components
- Can be tested and developed independently

### Connections (Data Flows)

Data flows between components through explicit connections:
- **Input Ports**: Where components receive data
- **Output Ports**: Where components send data
- **Information Packets (IPs)**: Data structures flowing between components

### Orchestrator

Coordinates the flow of data between components, defining:
- Which components to execute
- In what order
- How data flows between them

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     CLI Arguments                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  1. Config Component                                    │
│     - Parse arguments                                   │
│     - Validate options                                  │
│     - Parse dates                                       │
└────────────────────┬────────────────────────────────────┘
                     │ config hash
                     ▼
┌─────────────────────────────────────────────────────────┐
│  2. Auth Component                                      │
│     - Detect auth method (OAuth/Cookie)                │
│     - Prepare auth headers                              │
└────────────────────┬────────────────────────────────────┘
                     │ auth context
                     ▼
┌─────────────────────────────────────────────────────────┐
│  3. API Component                                       │
│     - HTTP client setup                                 │
│     - Request/response handling                         │
│     - JSON encoding/decoding                            │
└────────────────────┬────────────────────────────────────┘
                     │ api client
                     ▼
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌──────────────────┐   ┌──────────────────┐
│  4a. Search      │   │  4b. Download    │
│  Component       │   │  Component       │
│  - Search API    │   │  - List convos   │
│  - Filter msgs   │   │  - Get history   │
└────────┬─────────┘   └────────┬─────────┘
         │                       │
         │ messages array        │ messages array
         │                       │
         └───────────┬───────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  5. Filter Component                                    │
│     - Random search (wordlist)                          │
│     - Thread extraction                                 │
└────────────────────┬────────────────────────────────────┘
                     │ filtered messages
                     ▼
┌─────────────────────────────────────────────────────────┐
│  6. Output Component                                    │
│     - Format JSON                                       │
│     - Write to file                                     │
│     - Display summary                                   │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
              JSON file saved
```

---

## Data Flow

### Flow 1: Search Mode

```
CLI Args
  ↓
Config (keywords provided)
  ↓
Auth
  ↓
API Client
  ↓
Search Component
  ↓ [messages array]
Filter Component (threads)
  ↓ [filtered messages]
Output Component
  ↓
JSON File
```

### Flow 2: Download Mode

```
CLI Args
  ↓
Config (--download-all)
  ↓
Auth
  ↓
API Client
  ↓
Download Component
  ├─ Get Conversations
  ├─ For each conversation:
  │   ├─ Get History
  │   └─ Get Threads (if enabled)
  ↓ [messages array]
Output Component
  ↓
JSON File
```

### Flow 3: Random Search Mode

```
CLI Args
  ↓
Config (--random-search)
  ↓
Filter Component
  ├─ Load wordlist
  └─ Select random keyword
  ↓ [modified config]
Auth
  ↓
API Client
  ↓
Search Component (with random keyword)
  ↓ [messages array]
Filter Component (threads)
  ↓ [filtered messages]
Output Component
  ↓
JSON File
```

---

## Module Reference

### Core Modules

#### `Kasumi::Config`
**Location**: `lib/Kasumi/Config.pm`

**Responsibility**: Parse and validate command-line arguments

**Input**:
- `@ARGV` (command-line arguments)

**Output**:
- Configuration hash with all options

**Methods**:
- `new()` - Constructor
- `process($argv)` - Parse arguments
- `parse_date($date_str)` - Parse date string to timestamp
- `print_usage()` - Display help message

**Example**:
```perl
my $config = Kasumi::Config->new();
my $cfg = $config->process(\@ARGV);
```

---

#### `Kasumi::Auth`
**Location**: `lib/Kasumi/Auth.pm`

**Responsibility**: Handle Slack authentication

**Input**:
- Configuration hash (token, cookie)

**Output**:
- Auth context with methods to get headers

**Methods**:
- `new()` - Constructor
- `process($config)` - Initialize auth
- `get_headers()` - Get HTTP headers for API requests
- `get_token()` - Get auth token

**Example**:
```perl
my $auth = Kasumi::Auth->new();
$auth->process($config);
my $headers = $auth->get_headers();
```

---

#### `Kasumi::API`
**Location**: `lib/Kasumi/API.pm`

**Responsibility**: Slack API HTTP client

**Input**:
- Auth context
- SSL verification setting

**Output**:
- API client for making requests

**Methods**:
- `new($auth, $no_verify_ssl)` - Constructor
- `request($method, $url, $params)` - Make API request
- `uri_escape($str)` - URL encode string

**Example**:
```perl
my $api = Kasumi::API->new($auth, $config->{no_verify_ssl});
my $response = $api->request('GET', $url, \%params);
```

---

### Component Modules

#### `Kasumi::Component::Search`
**Location**: `lib/Kasumi/Component/Search.pm`

**Responsibility**: Search messages using Slack search API

**Input**:
- API client
- Search query
- Date range (oldest, latest)

**Output**:
- Array reference of matching messages

**Methods**:
- `new($api)` - Constructor
- `process($query, $oldest, $latest)` - Perform search

**Example**:
```perl
my $search = Kasumi::Component::Search->new($api);
my $messages = $search->process("password", $oldest, $latest);
```

---

#### `Kasumi::Component::Download`
**Location**: `lib/Kasumi/Component/Download.pm`

**Responsibility**: Download all messages from conversations

**Input**:
- API client
- Configuration (date range, threads, size limit)

**Output**:
- Array reference of all messages

**Methods**:
- `new($api)` - Constructor
- `process($config)` - Download all messages
- `get_conversations()` - Get list of conversations
- `get_conversation_history($channel_id, $oldest, $latest)` - Get messages
- `get_thread_replies($channel_id, $thread_ts)` - Get thread replies
- `get_conversation_type($conv)` - Determine conversation type

**Example**:
```perl
my $download = Kasumi::Component::Download->new($api);
my $messages = $download->process($config);
```

---

#### `Kasumi::Component::Filter`
**Location**: `lib/Kasumi/Component/Filter.pm`

**Responsibility**: Filter and transform messages

**Input**:
- Configuration (for random search)
- Messages array (for thread extraction)

**Output**:
- Modified configuration or messages

**Methods**:
- `new()` - Constructor
- `process_random_search($config)` - Load wordlist and select keyword
- `process_thread_extraction($messages, $api, $config)` - Fetch threads

**Example**:
```perl
my $filter = Kasumi::Component::Filter->new();
$filter->process_random_search($config);
$filter->process_thread_extraction($messages, $api, $config);
```

---

#### `Kasumi::Component::Output`
**Location**: `lib/Kasumi/Component/Output.pm`

**Responsibility**: Save results to JSON file

**Input**:
- Messages array
- Configuration (output file, filters used)

**Output**:
- JSON file written to disk
- Boolean success indicator

**Methods**:
- `new()` - Constructor
- `process($messages, $config)` - Save to JSON file

**Example**:
```perl
my $output = Kasumi::Component::Output->new();
$output->process($messages, $config);
```

---

### Flow Module

#### `Kasumi::Flow::Orchestrator`
**Location**: `lib/Kasumi/Flow/Orchestrator.pm`

**Responsibility**: Coordinate data flow between components

**Input**:
- Command-line arguments

**Output**:
- Execution result (success/failure)

**Methods**:
- `new()` - Constructor
- `run($argv)` - Execute the full flow
- `get_messages()` - Get extracted messages
- `get_config()` - Get configuration

**Flow Logic**:
1. Parse configuration
2. Setup authentication
3. Initialize API client
4. Process random search (if enabled)
5. Choose extraction method:
   - Search mode (if keywords provided)
   - Download mode (otherwise)
6. Process thread extraction (if enabled)
7. Save output

**Example**:
```perl
my $orchestrator = Kasumi::Flow::Orchestrator->new();
$orchestrator->run(\@ARGV);
```

---

## Extending Kasumi

### Adding a New Component

1. **Create the component module**:
```perl
package Kasumi::Component::MyComponent;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub process {
    my ($self, $input_data) = @_;

    # Your processing logic here
    my $output_data = transform($input_data);

    return $output_data;
}

1;
```

2. **Add to orchestrator**:
```perl
use Kasumi::Component::MyComponent;

# In Orchestrator::run():
my $my_component = Kasumi::Component::MyComponent->new();
my $result = $my_component->process($input);
```

### Example: Adding Email Output Component

**File**: `lib/Kasumi/Component/EmailOutput.pm`

```perl
package Kasumi::Component::EmailOutput;

use strict;
use warnings;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub process {
    my ($self, $messages, $config) = @_;

    return unless $config->{email_results};

    my $body = "Found " . scalar(@$messages) . " messages\n";
    my $email = Email::Simple->create(
        header => [
            To      => $config->{email_to},
            From    => 'kasumi@example.com',
            Subject => 'Kasumi Results',
        ],
        body => $body,
    );

    sendmail($email);
    print "[+] Results emailed to $config->{email_to}\n";

    return 1;
}

1;
```

**Usage in Orchestrator**:
```perl
# After Output component
if ($config->{email_results}) {
    my $email_output = Kasumi::Component::EmailOutput->new();
    $email_output->process($messages, $config);
}
```

---

## Testing Components

Each component can be tested in isolation:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Kasumi::Component::Search;

# Mock API client
my $mock_api = MockAPI->new();

# Test Search component
my $search = Kasumi::Component::Search->new($mock_api);
my $messages = $search->process("test", undef, undef);

is(ref($messages), 'ARRAY', 'Returns array reference');
ok(scalar(@$messages) > 0, 'Found messages');

done_testing();
```

---

## Directory Structure

```
kasumi/
├── kasumi.pl                  # Main script
├── lib/
│   └── Kasumi/
│       ├── Config.pm          # Configuration component
│       ├── Auth.pm            # Authentication component
│       ├── API.pm             # API client component
│       ├── Component/
│       │   ├── Search.pm      # Search component
│       │   ├── Download.pm    # Download component
│       │   ├── Filter.pm      # Filter component
│       │   └── Output.pm      # Output component
│       └── Flow/
│           └── Orchestrator.pm # Flow orchestrator
├── docs/
│   ├── README.md              # Main documentation
│   ├── ARCHITECTURE.md        # This file
│   ├── authentication.md
│   ├── search-modes.md
│   ├── download-modes.md
│   ├── advanced-options.md
│   ├── examples.md
│   └── troubleshooting.md
└── wordlist.txt               # Default wordlist
```

---

## Benefits of FBP Architecture

### 1. **Separation of Concerns**
Each component has a single responsibility:
- Config only handles configuration
- Auth only handles authentication
- Search only handles searching
- etc.

### 2. **Reusability**
Components can be reused in different contexts:
```perl
# Use Download component in another script
use Kasumi::Component::Download;

my $download = Kasumi::Component::Download->new($api);
my $messages = $download->get_conversation_history($channel_id);
```

### 3. **Testability**
Each component can be unit tested:
```perl
# Test Filter component with mock data
my $filter = Kasumi::Component::Filter->new();
my $keyword = $filter->process_random_search($mock_config);
is($keyword, 'expected_keyword', 'Random search works');
```

### 4. **Maintainability**
Changes are localized:
- Want to add new auth method? Modify only Auth.pm
- Want to support new output format? Add new Output component
- Want to change API client? Modify only API.pm

### 5. **Extensibility**
Easy to add new features:
- Add CSV output → Create Output::CSV component
- Add Elasticsearch indexing → Create Output::Elasticsearch component
- Add real-time monitoring → Create Monitor component

---

## Performance Considerations

### Component Overhead

FBP architecture adds minimal overhead:
- Each component instantiation: ~0.001s
- Data passing between components: negligible (references)
- Total overhead: <1% of execution time

### Optimization Opportunities

1. **Parallel Processing**: Components can be parallelized
2. **Caching**: Add caching layer between API and components
3. **Streaming**: Process messages in batches instead of all at once

---

## Using Kasumi

Kasumi uses Flow-Based Programming architecture for better maintainability and extensibility.

**Command-line usage:**
```bash
./kasumi.pl --token xoxp-your-token --keywords "password"
```

**Advantages of FBP architecture:**
- Better code organization
- Easier to maintain and extend
- Testable components
- Clearer data flow

---

## Further Reading

- [Flow-Based Programming](http://www.jpaulmorrison.com/fbp/) - J. Paul Morrison
- [Perl Best Practices](http://shop.oreilly.com/product/9780596001735.do) - Damian Conway
- [Object-Oriented Perl](http://shop.oreilly.com/product/9781884777790.do) - Damian Conway
