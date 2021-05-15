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
        let formattedToday = dateformat(today, "isoDateTime");
        let link = encodeURIComponent(t.link);
        const sql = `INSERT INTO treatise (psmid, url, last_run, year, processed) VALUES ('${t.psmid}', '${link}', '${formattedToday}', ${t.year}, false)`;
        return this.rawQuery(sql)
            .then((res) => {
                return res[0] || null;
            });
    }

    async updateTreatiseLastRun(psmid: string) {
        let today = new Date();
        let formattedToday = dateformat(today, "isoDateTime");

        const sql = `UPDATE treatise SET last_run = '${formattedToday}' where psmid = '${psmid}'`;
        // console.log(sql);
        return this.rawQuery(sql)
            .then((res) => {
                return res[0] || null;
            });
    }

    async setTreatiseProcessed(val: boolean, psmid: string) {
        const sql = `UPDATE treatise SET processed = true where psmid = '${psmid}'`;
        return this.rawQuery(sql)
            .then((res) => {
                return res[0] || null;
            });
    }

}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;