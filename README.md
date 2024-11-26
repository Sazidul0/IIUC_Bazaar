# IIUC Bazaar 📱🎯
A university-based e-commerce application designed exclusively for IIUC students. IIUC Bazaar simplifies the buying and selling of products within the university ecosystem, featuring secure authentication, role-based functionalities, and reliable payment methods.

---

## 📖 Table of Contents
1. [Features](#features)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Notification System](#notification-system)
7. [Screenshots](#screenshots)
8. [Challenges and Solutions](#challenges-and-solutions)
9. [Future Enhancements](#future-enhancements)
10. [License](#license)

---

## 🎯 Features

### Authentication
- **University Email Restriction**: Only emails ending with `@ugrad.iiuc.ac.bd` can sign up.
- **Secure Login**: Users can securely log in, and a "Forgot Password" option is available.

### User Roles
1. **Buyer**:
    - Add items to the cart.
    - Place orders with payment options.
    - View pending orders.
    - Give and manage reviews.
2. **Seller**:
    - Add, edit, and delete products.
    - Manage orders and view sales performance.
    - View and manage product reviews.

### Payment Options
- **Card Payment**: Securely integrated using **Stripe API**.
- **Cash on Delivery**: Available for users who prefer to pay on delivery.

### Delivery Location
- Predefined university locations, such as **FAZ**, **C Building**, **CXB**, etc., ensure efficient delivery.

---

## 🏗 Architecture
The application follows the **Model-View-ViewModel (MVVM)** pattern:
- **Model**: Manages data and business logic.
- **View**: Displays the UI and interacts with users.
- **ViewModel**: Connects the Model and View, handling user input and updating the UI.

---

## 💻 Technology Stack
1. **Frontend**: [Flutter](https://flutter.dev/)
2. **State Management**: [GetX](https://pub.dev/packages/get)
3. **Backend**: [Firebase](https://firebase.google.com/) (Authentication, Realtime Database, Storage)
4. **Payment Integration**: [Stripe API](https://stripe.com/)
5. **UI Enhancements**: Google Fonts, HexColor

---

## 🚀 Installation

### Prerequisites
- Flutter SDK
- Android Studio or VS Code
- Firebase account
- Stripe account for payment integration

### Steps
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Sazidul0/IIUC_Bazaar.git
   cd IIUC_Bazaar
