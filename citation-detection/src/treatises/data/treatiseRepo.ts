import * as _ from "lodash";

import Repository from "../../infrastructure/data/Repository";
import { CONN } from "../../infrastructure/data/knexProvider";
import { BookInfo, Citation } from './models';

class TreatiseRepo extends Repository {
    constructor() {
        super(BookInfo, CONN.ALT);
    }

    async getSampleTreatises() {
        const sql = `select * from book_info limit 5;`;
        let res = await this.rawQuery(sql);
        return res;
        // console.log(res);
        // let picked = _.map(res, (bi) => {
        //     _.pick(bi, ['psmid', 'contentType', 'id', 'pubdateComposed']);
        // });

        // console.log(picked);
    }

    async getTreatise(psmid: string) {
        const sql = `select * from treatise where psmid = ${psmid}`;
        return this.rawQuery(sql);
    }

}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;