import * as _ from "lodash";
import * as dateformat from "dateformat";

import Repository from "../../infrastructure/data/Repository";
import { CONN } from "../../infrastructure/data/knexProvider";
import { BookInfo, Citation, Treatise } from './models';

class TreatiseRepo extends Repository {
    constructor() {
        super(Treatise);
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
        let today = new Date();
        let formattedToday = dateformat(today, "YYYYMMDD"); 
        const sql = `INSERT INTO treatise (psmid, url, last_run, year, processed) VALUES (${t.psmid}, ${t.link}, ${formattedToday}, ${t.year}, true)`;
        return this.rawQuery(sql)
            .then((res) => {
                return res[0] || null;
            });
    }
}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;