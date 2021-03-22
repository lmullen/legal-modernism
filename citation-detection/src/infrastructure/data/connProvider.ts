import * as Knex from "knex";
import * as dotenv from "dotenv";

dotenv.config();

import config from "../../config";

interface IKnexConfig extends Knex.Config {
    ssl: boolean
}

class KnexConfig implements Knex.Config {
    ssl: boolean
    client: string;
    connection: string
}

let mainConn = new KnexConfig();
mainConn.ssl = true;
mainConn.client = "pg";
mainConn.connection = `postgres://${process.env.GMU_DB_USER}:${process.env.GMU_DB_PW}@${process.env.GMU_DB_HOST}`;

let altConn = new KnexConfig();
altConn.ssl = true;
altConn.client = "pg";
altConn.connection = `postgres://${process.env.TEST_DB_USER}:${process.env.TEST_DB_PW}@${process.env.TEST_DB_HOST}:5432/${process.env.TEST_DB}?ssl=true`;
console.log(altConn.connection);
// altConn.connection = process.env.TEST_DB_URI

export { mainConn, altConn };
