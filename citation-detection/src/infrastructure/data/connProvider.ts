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
altConn.connection = `postgres://${config.database.user}:${config.database.password}@${config.database.host}`;

export { mainConn, altConn };
