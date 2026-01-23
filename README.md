# Go-Student (Ub-Hub)

Go-Student is a comprehensive student portal application designed for the University of Buea. It provides students with a centralized hub for academic management, productivity tools, and resource access, all wrapped in a modern, professional user interface.

## Features

### 🔐 Authentication & Profile
- **Secure Login/Sign Up**: robust authentication system.
- **User Profile**: Manage personal details and settings.

### 🏠 Dashboard
- **Grid Layout**: Quick access to essential academic services.
- **Dynamic Greeting**: Personalized welcome message based on user data.

### 📚 Academic Management
- **Department Explorer**: View and manage university departments.
- **Course Registration**: Streamlined interface for registering courses (UI).
- **Result Checking**: Easy access to CA and Final Exam results.
- **Add Department**: Administrative feature to create new departments with **Mobile Money Payment Integration** (via Nkwa).

### 🛠️ Student Toolbox
Productivity tools built directly into the app:
- **GPA Calculator**: Calculate Semester and Cumulative GPA with support for UG and MBA grading scales.
- **Task Manager**: Organize academic and personal tasks with deadlines, priorities, and categories.
- **Focus Timer**: Built-in timer to manage study sessions effectively.
- **Document Scanner**: Scan and digitize physical documents.
- **Exam Schedule**: Keep track of upcoming examinations.
- **Flashcards / Resume Builder**: Tools for revision and career preparation.

### ⚙️ Settings & Customization
- **Theme Support**: Professional Blue (Light) and Dark Mode support.
- **Notifications**: Manage app alerts.

## Technology Stack

This project is built using **Flutter**.

- **State Management**: `provider`
- **Backend / Database**: `Supabase` (Auth & Database), `Firebase` (Core services)
- **UI/UX**: `google_fonts` (Outfit), `iconsax`, `google_nav_bar`
- **Utilities**: `intl`, `image_picker`, `url_launcher`
- **PDF Handling**: `syncfusion_flutter_pdfviewer`
- **ML/OCR**: `google_mlkit_text_recognition`

## Getting Started

### Prerequisites
- Flutter SDK (^3.9.2)
- Dart SDK

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ebongi/Ub-Hub.git
    cd Ub-Hub
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## Project Structure

- `lib/Screens/authentication`: Login and Registration logic.
- `lib/Screens/UI/preview/Navigation`: Main app shell (Home, Bottom Nav, Settings).
- `lib/Screens/UI/preview/Toolbox`: Productivity features (GPA Calculator, Task Manager, etc.).
- `lib/Screens/UI/preview/detailScreens`: Department and specific feature details.
- `lib/services`: Backend integrations (Supabase, Database, Department logic).

---
*Built with ❤️ for the students of the University of Buea.*
