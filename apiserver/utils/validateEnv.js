/**
 * Validate required environment variables
 * This prevents the app from starting with incomplete configuration
 */

const requiredEnvVars = [
    'NODE_ENV',
    'PORT_DEV',
    'DB_HOST',
    'DB_USER',
    'DB_PASS',
    'DB_NAME',
    'DB_PORT',
    'API_VERSION',
    'JWT_VERIFY_SECRET',
    'JWT_SESSION_SECRET',
    'SESSION_ENCRYPT_SECRET',
    'SESSION_ALGORITHM',
    'SESSION_COOKIE_NAME',
    'PASSWORD_HASH_CYCLE'
];

const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingVars.length > 0) {
    console.error('❌ Missing required environment variables:');
    missingVars.forEach(varName => {
        console.error(`   - ${varName}`);
    });
    console.error('\n📝 Please create a .env file with all required variables.');
    console.error('   You can copy from .env.example and fill in the values.\n');
    process.exit(1);
}

console.log('✅ All required environment variables are set');

module.exports = true;
