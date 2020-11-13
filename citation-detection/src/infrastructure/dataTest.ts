import config from "../config";
import * as Knex from "knex";
import * as _ from "lodash";

import BaseDataModel from "./BaseDataModel";

interface IKnexConfig extends Knex.Config {
    ssl: boolean
}

class KnexConfig implements Knex.Config {
    ssl: boolean
    client: string;
    connection: string
}

let c = new KnexConfig();
c.ssl = true;
c.client = "pg";
c.connection = "postgres://ss108:$ChangeMeAfterLogin$@baird.gmu.edu:5432/law";

const knex = Knex(c);

export async function rawQuery(query: string, params = []) {
        return knex.raw(query, params)
            .then((res) => {
                return res.rows.map((r) => {
                    let cased = _.mapKeys(r, (v, k) => {
                        return _.camelCase(String(k));
                    });

                    return cased;
                });
            });
    }