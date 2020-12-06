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

let testConn = new KnexConfig();
testConn.ssl = true;
testConn.client = "pg";
// testConn.connection = "postgres://rkrwfgiz:y9-a6iv0Yk-g3_U9QUvEG5Yxe4s5cPcV@ruby.db.elephantsql.com:5432/rkrwfgiz";
mainConn.connection = `postgres://${process.env.TEST_DB_USER}:${process.env.TEST_DB_PW}@${process.env.TEST_DB_HOST}`;

// const knex = Knex(mainConn);

export { mainConn, testConn };