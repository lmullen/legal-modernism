import * as _ from "lodash";

import Repository from "../../infrastructure/data/BaseDataManager";
import { altConn } from "../../infrastructure/data/connProvider";
import { BookInfo, Citation } from './models';

class TreatiseRepo extends Repository {
    constructor() {
        super(BookInfo);
    }

    async getSampleTreatises() {
        const sql = `select * from moml.book_info limit 5`;
        let res = await this.rawQuery(sql);
        return res;
        // console.log(res);
        // let picked = _.map(res, (bi) => {
        //     _.pick(bi, ['psmid', 'contentType', 'id', 'pubdateComposed']);
        // });

        // console.log(picked);

    }

    //needs to use alt db
    async getCitation(psmid: string, guid: string) {
        const sql = `select * from citation where psmid = ? and guid = ?`;
        return await this.rawQuery(sql, [psmid, guid], altConn);
    }

    async insertCitation(c: Citation) {
        const sql = `INSERT INTO citation (psmid, guid) VALUES (${c.psmid}, ${c.guid})`;
        return await this.rawQuery(sql, [], altConn);
    }

    async updateCitationCount(id: number | string, count: number) {
        const sql = `UPDATE citation SET count = ? WHERE id = ?`;
        return await this.rawQuery(sql, [count, id], altConn);
    }
}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;