# Nautilus Media Server

A high-performance, self-hosted media streaming server built with OCaml, featuring adaptive streaming, intelligent metadata management, and a modern web interface.

## 🚀 Key Features

- **Adaptive HLS Streaming** - Automatic quality adjustment and efficient video delivery
- **Smart Metadata Integration** - Automatic movie/TV show information via TMDB API
- **Byte-Range Streaming** - Optimized for large media files with resume capability
- **Real-time Transcoding** - FFmpeg integration for on-the-fly format conversion
- **Intelligent File Management** - Automatic media discovery and organization
- **Responsive Web Interface** - Modern UI with seamless playback controls

## 🛠 Technology Stack

- **Backend**: OCaml with Dream web framework
- **Database**: PostgreSQL with async Caqti driver
- **Streaming**: HLS (HTTP Live Streaming) with FFmpeg
- **Frontend**: Vanilla JavaScript with modern CSS
- **Infrastructure**: Docker Compose for easy deployment
- **Testing**: Comprehensive test suite with Alcotest

## 🏗 Architecture Overview

```
├── Web Interface (Dream)
├── Stream Service (HLS + Byte Range)
├── Media Metadata (TMDB Integration)
├── File Management (Auto-discovery)
├── Database Layer (PostgreSQL)
└── Infrastructure (Docker + FFmpeg)
```

### Core Components

- **Stream Handler**: Manages HLS segments and adaptive bitrate streaming
- **TMDB Client**: Fetches rich movie/TV metadata automatically  
- **File Service**: Handles media discovery, parsing, and organization
- **Database Repository**: Async PostgreSQL operations with proper migrations
- **Web Interface**: RESTful API with streaming-optimized endpoints

## 🎯 Technical Highlights

- **Functional Programming**: Leverages OCaml's type safety and performance
- **Async I/O**: Non-blocking streaming with Lwt for high concurrency
- **Video Streaming**: Implemented HLS protocol for adaptive streaming, fast scrubbing and broad support for different video types
- **Testing**: Unit tests for all core services and repositories

## 📦 Quick Start

### Prerequisites

- Docker & Docker Compose

### Installation

```bash
# Clone the repository
git clone https://github.com/jordan12sam/nautilus.git
cd nautilus

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Run the application
./run.sh
```

The server will be available at `http://localhost:8080`

### Configuration

```toml
# config.toml
[database]
host = "localhost"
port = 5432

[tmdb]
api_key = "your_tmdb_api_key"

[data]
data_directory = "/path/to/your/media"
```

## 🧪 Testing

```bash
# Run test script
./run-test.sh
```

## 🔧 Development

### Project Structure

```
lib/
├── client/          # External API clients (TMDB)
├── database/        # Repository pattern with migrations
├── handler/         # HTTP request handlers  
├── service/         # Business logic and streaming
├── model/          # Domain types and data structures
└── utils/          # Shared utilities and helpers
```