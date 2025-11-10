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
7. [Demo Video](#demo-video)
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

2. **Install Dependencies**:
   ```bash flutter pub get
   ```

3. **Set Up Firebase**:
   - Add your google-services.json (Android) and GoogleService-Info.plist (iOS) files.
   - Enable Authentication and Realtime Database in Firebase Console.

4. **Configure Stripe API**:
   - Replace the placeholder API keys in payment_service.dart with your Stripe credentials.

5. **Run the App**:
   ```bash flutter run
   ```



## 📚 Usage
### Buyer Workflow
1. **Signup**: Register with your university email (@ugrad.iiuc.ac.bd).
2. **Browse Products**: Add items to your cart.
3. **Place Orders**: Choose a payment method and specify a delivery location.
4. **Manage Orders**: Track pending orders and give product reviews.

### Seller Workflow
1. **Signup/Login**: Register as a seller using your university email.
2. **Manage Products**: Add, update, or delete products.
3. **View Sales**: Analyze performance and orders.
4. **Manage Orders**: Process and update order statuses.

---

# 🔔 Notification System

## Buyer Notifications:
- **Card Payment**: Payment success notification.
- **Cash on Delivery**: Order confirmation notification.

## Seller Notifications:
- **New order alerts** with delivery details.

Notifications ensure a seamless buying and selling experience.


# 📹 Demo Video

<!-- Using HTML to control the image size and link to Google Drive -->
<a href="https://drive.google.com/file/d/1EsV_THOWT_rg8eOT8RUDRO2h_3VH0Vai/view?usp=sharing">
    <img src="https://i.ibb.co/com/F5HLWHY/6206247504320774581.jpg" alt="Demo Video" width="400"/>
</a>



## 🛠 Challenges and Solutions
- **Challenge**: Restricting Access  
  **Solution**: Validate email domain for `@ugrad.iiuc.ac.bd`.

- **Challenge**: Role-Specific Functionalities  
  **Solution**: Designed separate UIs and backend logic for buyers and sellers.

- **Challenge**: Secure Payment Integration  
  **Solution**: Integrated Stripe API for safe card payments.

## 🌟 Future Enhancements
- Add real-time chat between buyers and sellers.
- Expand delivery location options.
- Integrate advanced analytics for seller performance.
- Introduce AI-based product recommendations.

## 📜 License
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing
Contributions are welcome!

1. Fork the repository.
2. Create a new branch.
3. Commit your changes.
4. Open a pull request.

## 👩‍💻 Contact
**Developer**: [Sazidul Islam]  
**GitHub**: [https://github.com/Sazidul0]
