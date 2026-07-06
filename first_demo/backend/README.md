# PHP REST Backend — first_demo

## Folder Structure
```
backend/
├── api/
│   └── auth/
│       ├── signup.php     # POST  — Register a new customer
│       ├── login.php      # POST  — Authenticate & receive JWT
│       ├── me.php         # GET   — Get authenticated user profile (requires JWT)
│       └── logout.php     # POST  — Stateless logout (discard JWT on client)
├── config/
│   └── database.php       # DB credentials + auto-create DB & tables
├── helpers/
│   ├── jwt.php            # Pure-PHP HS256 JWT implementation
│   ├── response.php       # JSON response helpers
│   └── validation.php     # Input sanitization & validation helpers
└── README.md
```

---

## Requirements
- PHP >= 7.4
- MySQL >= 5.7 / MariaDB >= 10.3
- Apache / Nginx (or PHP built-in server for local testing)

---

## Setup

### 1. Configure Database Credentials
Edit `config/database.php`:
```php
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', 'your_password');
define('DB_NAME', 'first_demo_db');
define('JWT_SECRET', 'change_this_to_a_long_random_string');
```

### 2. Place in Web Server
Copy the `backend/` folder into your web server root (e.g., `htdocs/` for XAMPP or `www/` for WAMP).

### 3. Database Auto-Setup
The database and `customers` table are **created automatically** on the first API call. No manual SQL import needed.

---

## Customers Table Schema
| Column           | Type            | Notes                         |
|-----------------|-----------------|-------------------------------|
| `id`            | INT UNSIGNED PK | Auto-increment                |
| `full_name`     | VARCHAR(150)    | From signup form              |
| `email`         | VARCHAR(255)    | Unique, indexed               |
| `password`      | VARCHAR(255)    | bcrypt hash (cost 12)         |
| `is_active`     | TINYINT(1)      | 1 = active, 0 = deactivated   |
| `email_verified`| TINYINT(1)      | 0 = unverified                |
| `profile_picture`| VARCHAR(500)   | Nullable                      |
| `last_login_at` | DATETIME        | Updated on every login        |
| `created_at`    | DATETIME        | Set on INSERT                 |
| `updated_at`    | DATETIME        | Auto-updated on row change    |

---

## API Reference

### Sign Up
```
POST /backend/api/auth/signup.php
Content-Type: application/json

{
  "full_name":        "John Doe",
  "email":            "john@example.com",
  "password":         "Secret123",
  "confirm_password": "Secret123"
}
```
**Response 201:**
```json
{
  "success": true,
  "message": "Account created successfully.",
  "data": {
    "token": "<JWT>",
    "customer": { "id": 1, "full_name": "John Doe", "email": "john@example.com", ... }
  }
}
```

---

### Login
```
POST /backend/api/auth/login.php
Content-Type: application/json

{
  "email":    "john@example.com",
  "password": "Secret123"
}
```
**Response 200:**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "<JWT>",
    "customer": { "id": 1, "full_name": "John Doe", "email": "john@example.com", ... }
  }
}
```

---

### Get Profile (Protected)
```
GET /backend/api/auth/me.php
Authorization: Bearer <JWT>
```
**Response 200:**
```json
{
  "success": true,
  "message": "Profile fetched.",
  "data": { "customer": { ... } }
}
```

---

### Logout
```
POST /backend/api/auth/logout.php
Authorization: Bearer <JWT>
```
**Response 200:**
```json
{
  "success": true,
  "message": "Logged out successfully. Please discard your token on the client side."
}
```

---

## Security Features
- ✅ **bcrypt password hashing** (cost factor 12) via `password_hash()` / `password_verify()`
- ✅ **HS256 JWT tokens** — pure PHP, no external library
- ✅ **JWT expiry** — tokens expire after 24 hours (configurable via `JWT_EXPIRY`)
- ✅ **Prepared statements** — all queries use PDO with parameter binding (SQL injection protection)
- ✅ **Email uniqueness** enforced at DB + application level
- ✅ **CORS headers** for Flutter mobile/web client compatibility
- ✅ **Timing-safe** password comparison prevents timing attacks
- ✅ **Password never returned** in any API response

---

## Flutter Integration

Add the `http` package to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.0
```

Example signup call in Dart:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'http://your-server-ip/backend/api/auth';

Future<Map<String, dynamic>> signUp({
  required String fullName,
  required String email,
  required String password,
  required String confirmPassword,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/signup.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'full_name':        fullName,
      'email':            email,
      'password':         password,
      'confirm_password': confirmPassword,
    }),
  );
  return jsonDecode(res.body);
}

Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/login.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  return jsonDecode(res.body);
}
```
