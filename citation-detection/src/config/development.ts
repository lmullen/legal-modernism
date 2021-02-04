import * as dotenv from "dotenv";
dotenv.config();

const developmentConfig = {
    database: {
        host: process.env.TEST_DB_HOST,
        database: process.env.TEST_DB,
        user: process.env.TEST_DB_USER,
        password: process.env.TEST_DB_PW,
        ssl: true
    }
};

export default developmentConfig;