import * as _ from "lodash";

import Repository from "../../infrastructure/data/Repository";
import { CONN } from "../../infrastructure/data/knexProvider";
import { Citation } from './models';

class CitationRepo extends Repository {
    constructor() {
        super(Citation);
    }

    async getCitation(psmid: string, guid: string) {
        const sql = `select * from citation where psmid = ? and guid = ?`;
        return await this.rawQuery(sql, [psmid, guid])
            .then((res) => {
                return res[0] || null;
            });
    }

    async insertCitation(c: Citation) {
        const sql = `INSERT INTO citation (psmid, guid, count) VALUES ('${c.psmid}', '${c.guid}', ${c.count})`;
        return await this.rawQuery(sql, []);
    }

    async updateCitationCount(id: number | string, count: number) {
        const sql = `UPDATE citation SET count = ? WHERE id = ?`;
        // console.log(sql);
        return await this.rawQuery(sql, [count, id]);
    }

    async clearCitations(psmid: string) {
        const sql = `DELETE from citation where psmid = ?`;
        return await this.rawQuery(sql, [psmid])
            .then((res) => {
                return res[0] || null;
            });
    }
}

const instance = new CitationRepo();
Object.seal(instance);
export default instance