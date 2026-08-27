# StageManager (Event Control Hub)

StageManager is a real-time web application designed to manage live events, presentations, and timers across multiple screens seamlessly. Built with Ruby on Rails 8, it leverages ActionCable and Turbo Streams to deliver instant synchronization without the need for manual browser refreshes.

## 🚀 Key Features

*   **Room-Based Architecture**: Create unique rooms secured by alphanumeric passcodes.
*   **Real-time Timer Controls**:
    *   Start, Pause, and Reset a live countdown timer.
    *   Add or subtract time on the fly.
    *   Configure a default initial timer duration (e.g., `15:00`, `54:00`).
*   **Dynamic Carousel Messaging**: Push live announcements or messages that scroll across the participant screens.
*   **Multi-Screen Output**:
    *   **Manager Interface** (`/rooms/:passcode/manager`): The command center for event organizers to control timers, messages, and media.
    *   **Timer Display** (`/rooms/:passcode/timer`): A clean, distraction-free fullscreen countdown clock for speakers or participants.
    *   **Presentation Screen** (`/rooms/:passcode/presentation`): The main visual display for slides and media (functionality expanding in the next phase).

## 🛠 Technology Stack

*   **Framework**: [Ruby on Rails 8.1](https://rubyonrails.org/)
*   **Language**: [Ruby 3.4](https://www.ruby-lang.org/)
*   **Database**: PostgreSQL
*   **Real-time Synchronization**: Hotwire (Turbo Streams) & Solid Cable
*   **Styling**: Bootstrap 5 + Custom CSS
*   **Background Jobs**: Solid Queue

## 💻 Local Development Setup

StageManager is designed to run within the larger `services-infra` Docker Compose environment.

### Prerequisites
* Docker & Docker Compose
* Configured `services-infra` workspace

### Running the Application
1. Ensure your PostgreSQL database container (`postgres-db`) is running in your `services-infra` environment.
2. The `stagemanager` service is configured with the `donotstart` profile in `compose.dev.yaml`. Start it explicitly:
   ```bash
   docker compose --profile donotstart up stagemanager
   ```
3. Run database migrations:
   ```bash
   docker compose exec stagemanager bin/rails db:prepare
   ```
4. Access the application locally via the reverse proxy at `http://stagemanager.farmacia.local` (ensure your `/etc/hosts` file is configured properly) or `http://localhost:8004`.

## 🏗 Architecture & Design

StageManager utilizes a monolithic architecture optimized for real-time performance:
*   **No-JS Overhead**: By heavily leveraging Rails Hotwire, complex state management is kept on the server, while Turbo Streams handle DOM updates over WebSockets.
*   **Solid Cable**: Real-time pub/sub is backed entirely by the PostgreSQL database via Solid Cable, removing the dependency on Redis.
*   **Active Job**: Background tasks (like automatic timer ticks) are handled efficiently using `TimerTickJob` combined with Solid Queue.

## 📝 Future Roadmap

*   **Presentations & Media**: Full integration for uploading, ordering, and broadcasting presentation slides to connected screens.
*   **Media Asset Management**: Active Storage configuration for robust media handling.
*   **Keyboard Media Shortcuts**: Allow users to map uploaded media to keyboard keys (for example, assign `exit-music.mp3` to `1`) so pressing the mapped key on the page starts playback.
*   **Authentication & Roles**: Enhanced security beyond room passcodes for organizational event management.

---
*Developed by the IT Support Team at Faculdade de Farmácia (FAFAR).*
