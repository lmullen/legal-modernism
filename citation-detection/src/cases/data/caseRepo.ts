import * as _ from "lodash";

import Repository from "../../infrastructure/data/Repository";
import { Case } from "./models";
import { altConn } from "../../infrastructure/data/connProvider";

class CaseRepo extends Repository {
    constructor() {
        super(Case, altConn);
    }

    //@TODO: use Objection properly and set appropriate DB on queries
    async insertCase(c: Case) {
        let sql = `INSERT INTO "caseTable" (case_dot_law_id, full_name, short_name, year, guid) VALUES (${c.caseDotLawId}, '${c.fullName}', '${c.shortName}', ${c.year}, '${c.guid}')`;
        // console.log(sql);
        return this.rawQuery(sql);
    }

    async fetchCase(guid: string) {
        const sql = `SELECT * FROM case where guid = ?`;
        return this.rawQuery(sql, [guid]);
    }

}

const instance = new CaseRepo();
Object.seal(instance);
export default instance;