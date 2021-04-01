import * as _ from "lodash";

import Repository from "../../infrastructure/data/Repository";
import { CONN } from "../../infrastructure/data/knexProvider";
import { BookInfo, Citation, Treatise } from './models';

class TreatiseRepo extends Repository {
    constructor() {
        super(Treatise, CONN.ALT);
    }

    async getTreatise(psmid: string) {
        const sql = `select * from treatise where psmid = '${psmid}'`;
        return this.rawQuery(sql)
            .then((res) => {
                return res[0] || null;
            });
    }

    async createTreatise(t: Treatise) {
        // await this.create(t);
        const sql = `select * `
    }
}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;