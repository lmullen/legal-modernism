import * as dotenv from "dotenv";
dotenv.config();

const developmentConfig = {
    database: {
        host: process.env.DB_HOST,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PW,
        ssl: true
    }
};

export default developmentConfig;