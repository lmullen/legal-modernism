import * as Knex from "knex";
import * as dotenv from "dotenv";

dotenv.config();

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
mainConn.connection = `postgres://${process.env.MAIN_DB_USER}:${process.env.MAIN_DB_PW}@${process.env.MAIN_DB_HOST}`;
console.log(mainConn.connection);

let altConn = new KnexConfig();
altConn.ssl = true;
altConn.client = "pg";
mainConn.connection = `postgres://${process.env.TEST_DB_USER}:${process.env.TEST_DB_PW}@${process.env.TEST_DB_HOST}`;

// const knex = Knex(mainConn);

export { mainConn, altConn };