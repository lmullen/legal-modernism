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
mainConn.connection = "postgres://ss108:$ChangeMeAfterLogin$@baird.gmu.edu:5432/law";

// const knex = Knex(mainConn);

export { mainConn }