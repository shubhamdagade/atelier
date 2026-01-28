# Atelier MEP Portal

A comprehensive MEP (Mechanical, Electrical, Plumbing) project management portal built with React, Vite, Tailwind CSS, and PostgreSQL.

## Features

### User Levels
- **Super Admin**: Access to all dashboards and project standards management
- **L1 (Admin)**: Project allocation and lead assignment
- **L2 (Lead)**: Project tracking and execution
- **L3 (Supervisor)**: Read-only project view with progress tracking
- **L4 (Team Member)**: View-only access to assigned projects

### Project Management
- Hierarchical project creation with buildings, floors, and flats
- Google Maps integration for location selection
- Material Approval Sheets (MAS) management
- Requests for Information (RFI) tracking
- Auto-save functionality for project forms
- Live preview of project data
- Twin building feature for data duplication

## Setup

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```
# Firebase Configuration
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=
VITE_FIREBASE_PROJECT_ID=
VITE_FIREBASE_STORAGE_BUCKET=
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=

# Google Maps Configuration
VITE_GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Database Configuration
DB_USER=
DB_PASSWORD=
DB_HOST=
DB_NAME=
INSTANCE_CONNECTION_NAME=

# Environment
NODE_ENV=development
```

### Getting Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable the following APIs:
   - Maps JavaScript API
   - Places API
4. Create an API key (Credentials → Create Credentials → API Key)
5. Add the key to your `.env` file as `VITE_GOOGLE_MAPS_API_KEY`
6. Add your domain to the API key restrictions

### Installation

```bash
npm install
npm run init:db
npm run dev
```

## Database

PostgreSQL schema includes tables for users, projects, buildings, floors, flats, material approval sheets, and requests for information with proper relationships and cascading deletes.

Initialize database:
```bash
npm run init:db
```

## Tech Stack

- **Frontend**: React 19, React Router 7, Vite 7, Tailwind CSS 3, Lucide React icons
- **Backend**: Express.js 4, ES Modules
- **Database**: PostgreSQL 8
- **Authentication**: Firebase
- **Maps**: Google Maps API & Places API

## Building

```bash
npm run build
```
