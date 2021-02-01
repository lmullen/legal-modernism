require('dotenv').config();

module.exports = {
    development: {
        client: 'pg',
        connection: {
            host: process.env.TEST_DB_HOST,
            database: process.env.TEST_DB,
            user: process.env.TEST_DB_USER,
            password: process.env.TEST_DB_PW,
            ssl: true
        }
    }
};
