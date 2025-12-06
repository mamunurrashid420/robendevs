const path = require("path")

const express = require("express")
const cookieParser = require('cookie-parser')
const compression = require('compression')
const cors = require('cors')
const helmet = require("helmet")
const morgan = require("morgan")
const rateLimit = require('express-rate-limit')

const api = require("./api")
const convertErrors = require('./middleware/convertErrors')
const handleErrors = require('./middleware/handleErrors')
const app = express()

// Health check endpoint for Docker/K8s (before any middleware)
app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() })
})

// parsing cookies for auth
app.use(cookieParser())

// setting up logger
if (process.env.NODE_ENV === "development") {
    app.use(morgan("dev"))
}

// CORS configuration
const corsOptions = {
    origin: process.env.NODE_ENV === "production"
        ? [process.env.CLIENT_URL_DEV, process.env.API_URL_DEV].filter(Boolean)
        : true, // Allow all origins in development
    credentials: true, // Allow cookies to be sent
    optionsSuccessStatus: 200
}
app.use(cors(corsOptions))

// setting security HTTP headers
app.use(helmet({
    crossOriginResourcePolicy: false,
}))

// Rate limiting - prevent brute force attacks
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: { status: 'error', message: 'Too many requests, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
})
app.use('/api', limiter)

// parsing incoming requests with JSON body payloads
app.use(express.json({ limit: '10mb' }))

// parsing incoming requests with urlencoded body payloads
app.use(express.urlencoded({ extended: true, limit: '10mb' }))

// serving the static files
app.use(express.static(path.join(__dirname, "../", "client/", "build")))
app.use(express.static(path.join(__dirname, "images")))

// handling gzip compression
app.use(compression())

// redirecting incoming requests to api.js
app.use(`/api/${process.env.API_VERSION}`, api)

// returning the main index.html, so react-router render the route in the client
// Only for non-API routes (let React Router handle client-side routing)
app.get("*", (req, res, next) => {
    // Skip if it's an API request that wasn't handled
    if (req.path.startsWith('/api/')) {
        return next()
    }
    res.sendFile(path.resolve(__dirname, "../", "client/", "build", "index.html"))
})

// setting up a 404 error handler for unhandled API routes
app.all("*", (req, res) => {
    res.status(404).json({ status: 'error', message: `Route ${req.originalUrl} not found` })
})

// convert&handle errors
app.use(convertErrors)
app.use(handleErrors)

module.exports = app