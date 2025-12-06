# Quick Fixes Guide

Fix these critical issues immediately.

## 1. Update Docker Images (CRITICAL)

### Dockerfile.backend
```dockerfile
# ❌ BEFORE (Vulnerable)
FROM node:16-alpine

# ✅ AFTER (Secure)
FROM node:20-alpine
```

### Dockerfile.frontend  
```dockerfile
# ❌ BEFORE (Vulnerable)
FROM node:16-alpine

# ✅ AFTER (Secure)
FROM node:20-alpine
```

---

## 2. Fix .env Loading Path (HIGH)

**File**: `apiserver/index.js` line 2

```javascript
// ❌ BEFORE
dotenv.config({ path: './.config.env' })

// ✅ AFTER
dotenv.config()  // Loads .env from current directory
```

---

## 3. Change Logout to POST (HIGH)

**File**: `apiserver/routes/authRoutes.js`

```javascript
// ❌ BEFORE
.get("/logout", authController.logout)

// ✅ AFTER
.post("/logout", authController.logout)
```

**Also update frontend**:

**File**: `client/src/services/authService.js`

```javascript
// ✅ ADD THIS METHOD
logoutUser() {
    return this.request.post("/api/v1/auth/logout");
}
```

---

## 4. Fix File Deletion to be Async (HIGH)

**File**: `apiserver/controllers/userController.js` line 26

```javascript
// ❌ BEFORE (Fire and forget)
if (oldUser.profileImg) {
    const oldImagePath = `./${process.env.IMAGES_DIR}/${oldUser.profileImg.slice(hostUrl.length + 1)}`;
    fs.unlink(oldImagePath, (err) => {
        if (err) {
            return next(new AppError(500, err.message));
        }
    })
}

// ✅ AFTER (Promise-based)
if (oldUser.profileImg) {
    const oldImagePath = `./${process.env.IMAGES_DIR}/${oldUser.profileImg.slice(hostUrl.length + 1)}`;
    try {
        await fs.promises.unlink(oldImagePath);
    } catch (err) {
        return next(new AppError(500, err.message));
    }
}
```

---

## 5. Remove passwordConfirm from Database (MEDIUM)

**File**: `apiserver/models/sampledb/user.js`

Add this hook at the end of the User model definition:

```javascript
// Add before closing the model definition
User.addHook('beforeCreate', async (user) => {
    // Password is already hashed by User model's beforeValidate hook
    // Remove passwordConfirm field before saving
    delete user.passwordConfirm;
});

return User;
```

Or better - update the authService to not pass passwordConfirm:

**File**: `apiserver/services/authService.js`

```javascript
// ❌ BEFORE
const newUser = await User.create({
    firstName,
    lastName,
    email,
    password,
    passwordConfirm
})

// ✅ AFTER
const newUser = await User.create({
    firstName,
    lastName,
    email,
    password
    // Don't pass passwordConfirm to database
})
```

---

## 6. Fix Authorization Middleware (LOW)

**File**: `apiserver/middleware/athorizeOnly.js` - Rename to `authorizeOnly.js`

```javascript
// ❌ BEFORE
return next(new AppError('You are not authorized to perform this action!', 403));

// ✅ AFTER (Correct parameter order)
return next(new AppError(403, 'You are not authorized to perform this action!'));
```

**Update import in routes**:
```javascript
// Find where it's imported and update
const authorizeOnly = require('../middleware/authorizeOnly');
```

---

## 7. Improve React Hook (MEDIUM)

**File**: `client/src/hooks/useCheckAuth.js`

```javascript
// ❌ BEFORE
const { request } = useRef(createHttpClient()).current;

// ✅ AFTER
const httpClientRef = useRef(null);
if (!httpClientRef.current) {
    httpClientRef.current = createHttpClient();
}
const { request } = httpClientRef.current;
```

---

## 8. Add Input Validation (MEDIUM)

Create new file: `apiserver/middleware/validateInput.js`

```javascript
const { body, validationResult } = require('express-validator');
const AppError = require('../utils/appError');

const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        const message = errors.array().map(e => e.msg).join('; ');
        return next(new AppError(400, message));
    }
    next();
};

module.exports = {
    validate,
    registerValidation: [
        body('firstName').trim().notEmpty().withMessage('First name is required'),
        body('lastName').trim().notEmpty().withMessage('Last name is required'),
        body('email').isEmail().withMessage('Valid email is required'),
        body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
        body('passwordConfirm').custom((value, { req }) => {
            if (value !== req.body.password) {
                throw new Error('Passwords do not match');
            }
            return true;
        }),
    ],
    loginValidation: [
        body('email').isEmail().withMessage('Valid email is required'),
        body('password').notEmpty().withMessage('Password is required'),
    ]
};
```

Update auth routes:

**File**: `apiserver/routes/authRoutes.js`

```javascript
const { registerValidation, loginValidation, validate } = require('../middleware/validateInput');

router
    .post("/register", registerValidation, validate, authController.register)
    .post("/login", loginValidation, validate, authController.login)
    // ... rest
```

**Install dependency**:
```bash
npm install express-validator
```

---

## 9. Add Rate Limiting (MEDIUM)

Create file: `apiserver/middleware/rateLimiter.js`

```javascript
const rateLimit = require('express-rate-limit');

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 requests per windowMs
    message: 'Too many login attempts, please try again later',
    standardHeaders: true,
    legacyHeaders: false,
});

module.exports = { authLimiter };
```

Update auth routes:

```javascript
const { authLimiter } = require('../middleware/rateLimiter');

router
    .post("/register", authLimiter, ...)
    .post("/login", authLimiter, ...)
```

Install dependency:
```bash
npm install express-rate-limit
```

---

## 10. Improve Loading Component (LOW)

**File**: `client/src/components/shared/Loading.jsx`

```jsx
import React from 'react'
import { Spin } from 'antd'

export default function Loading() {
    return (
        <div style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '100vh'
        }}>
            <Spin size="large" tip="Loading..." />
        </div>
    )
}
```

---

## Testing the Fixes

After applying fixes, test each one:

```bash
# 1. Test Docker builds
docker build -f Dockerfile.backend -t backend-test .
docker build -f Dockerfile.frontend -t frontend-test .

# 2. Test environment loading
cd apiserver
npm start  # Should load .env correctly

# 3. Test logout endpoint
curl -X POST http://localhost:8010/api/v1/auth/logout

# 4. Test validation
curl -X POST http://localhost:8010/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"firstName":"test"}'  # Should return validation error

# 5. Test rate limiting
for i in {1..10}; do
  curl -X POST http://localhost:8010/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test","password":"test"}'
done
```

---

## Checklist

- [ ] Update Docker images to Node 20
- [ ] Fix .env loading path
- [ ] Change logout to POST
- [ ] Fix file deletion async
- [ ] Remove passwordConfirm from DB
- [ ] Fix authorization middleware
- [ ] Improve useCheckAuth hook
- [ ] Add input validation
- [ ] Add rate limiting
- [ ] Improve Loading component
- [ ] Test all changes
- [ ] Update docker-compose if needed
- [ ] Commit changes to git

---

## Resources

- [Express Validator Docs](https://express-validator.github.io/docs/)
- [Express Rate Limit Docs](https://github.com/nfriedly/express-rate-limit)
- [Security Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
