import * as Knex from "knex";

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
// mainConn.connection = "postgres://ss108:$ChangeMeAfterLogin$@baird.gmu.edu:5432/law";


let testConn = new KnexConfig();
testConn.ssl = true;
testConn.client = "pg";
testConn.connection = "postgres://rkrwfgiz:y9-a6iv0Yk-g3_U9QUvEG5Yxe4s5cPcV@ruby.db.elephantsql.com:5432/rkrwfgiz";

// const knex = Knex(mainConn);

export { mainConn, testConn };