require('dotenv').config();

// module.exports = {
//     development: {
//         client: 'pg',
//         connection: {
//             host: process.env.TEST_DB_HOST,
//             database: process.env.TEST_DB,
//             user: process.env.TEST_DB_USER,
//             password: process.env.TEST_DB_PW,
//             ssl: true
//         }
//     }
// };

module.exports = {
    development: {
        client: 'pg',
        connection: {
            host: process.env.GMU_DB_HOST,
            database: process.env.GMU_DB,
            user: process.env.GMU_DB_USER,
            password: process.env.GMU_DB_PW,
            ssl: true
        }
    }
};