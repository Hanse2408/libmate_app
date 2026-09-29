# LibMate Project Instructions

Project: LibMate - Library Book Reservation and Reading-Room Seat Booking Mobile App
Module: IT3060 HCI - Milestone 03
Team size: 4

## Technology Stack
- Flutter / Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Provider for state management
- go_router for navigation
- GitHub for version control

## Git Workflow
- main = stable/final version
- develop = integration branch
- feature branches = individual work
- Never make unrelated changes.
- Do not modify another member's feature unless required for integration.

## Team Feature Ownership
- Hansamal: Student seat booking flow + related seat reservations + notifications
- Dakshika: Student book reservation flow
- Gunasekara: Librarian flow
- Gunarathne: Library Manager flow

## Project Architecture

lib/
  app/
    routes/
    theme/

  core/
    constants/
    services/
    utils/
    widgets/

  models/

  repositories/

  features/
    auth/

    student/
      common/
      seat_booking/
        screens/
        widgets/
        providers/
      book_reservation/
        screens/
        widgets/
        providers/
      notifications/
        screens/
        widgets/
        providers/

    librarian/
      screens/
      widgets/
      providers/

    manager/
      screens/
      widgets/
      providers/

assets/
  images/
    books/
    profiles/
    common/
  icons/
  logos/

## Main Shared Models
- User
- Book
- Seat
- Reservation
- Notification
- Policy

## Planned Firestore Collections
- users
- books
- seats
- reservations
- notifications
- policies

## Coding Rules
1. Keep UI, state management, and Firebase/database logic separated.
2. Screen -> Provider -> Repository -> Firebase service.
3. Do not put Firestore queries directly inside UI widgets.
4. Reusable UI components should go into widgets folders.
5. Shared widgets/services belong in core.
6. Keep files small and focused.
7. Use clear Dart file names in snake_case.
8. Follow existing LibMate design and do not redesign screens unless requested.
9. Do not add unnecessary packages.
10. Do not add Firebase implementation until explicitly requested.
11. Do not delete or rewrite existing working code unless necessary.
12. Prefer simple implementation suitable for a university project.
13. Code must remain understandable for viva explanation.
14. Avoid over-engineering.
15. After changes, run flutter analyze and fix reasonable errors.
16. Explain briefly what files were created or changed.

## Current Priority
Build the shared project structure first.
Firebase integration and actual feature implementation will be done later.