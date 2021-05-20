import config from "../../config";
import * as Knex from "knex";
import * as _ from "lodash";
// import * as Objection from "objection";

import { getKnex, CONN } from "./knexProvider";
import { Model } from 'objection';

abstract class Repository {
    private readonly _model: Model;
    private readonly _knex;

    constructor(m, c?) {
        this._model = m;
        this._knex = (getKnex(c)); 
    }

    //this doesn't work for some reason. would be a solid QoL improvement if it was made to work
    get q() {
        return this._model.query(this._knex);
    }

    create(item) {
        return this.q.insertAndFetch(item);
    }

    update(obj: { id: number }) {
        return this.q.update(obj).where('id', obj.id);
    }

    getAll() {
        return this.q;
    }

    /**
     * Returns one
     * @param fieldName 
     * @param val 
     */
    getBy(fieldName: string, val: any) {
        const sql = `select * from "${this._model.tableName}" where ${fieldName} = '${val}'`;
        // const sql = `select * from ? where ? = ?`;
        return this.rawQuery(sql)
         .then((res) => {
            return res[0] || null;
        });
        //not working for some reason
        // return this._model.query()
        //     .where(fieldName, '=', val)
        //     .then((res) => {
        //         return res[0] || null;
        //     });
    }

    get(id: number | string) {
        return this.getBy('id', id);
    }

    //TODO: cleanup so not redundant with getBy
    /**
     * Returns array
     * @param fieldName 
     * @param val 
     */
    getWhere(fieldName: string, val: any) {
        return this.q.where(fieldName, '=', val);
    }

    /**
     * Don't use this on big tables (not that we have any at the time of this writing)--
     * it fetches all records from the DB first and then filters them using the built in filter.
     * If we use this a lot/need to use it on big tables, then this method should be refactored to take an object that it uses to dynamic chain "where"s onto the query.
     * @param {fn} filter
     * @returns A collection of the Model
     */
    async filter(filter: (x: any) => boolean) {
        let all = await this.getAll();
        return all.filter(filter);
    }

    /**
     * 
     * 
     * @param {any} id
     * @returns
     */
    delete(id: number) {
        return this.q.deleteById(id);
    }

    rawQuery(query: string, params = []) {
        return this._knex.raw(query, params)
            .then((res) => {
                return res.rows.map((r) => {
                    let cased = _.mapKeys(r, (v, k) => {
                        return _.camelCase(String(k));
                    });

                    return cased;
                });
            });
    }
}

export default Repository;