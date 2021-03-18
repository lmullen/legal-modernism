import * as _ from "lodash";

import Repository from "../../infrastructure/data/Repository";
import { altConn } from "../../infrastructure/data/connProvider";
import { BookInfo, Citation } from './models';

class TreatiseRepo extends Repository {
    constructor() {
        super(BookInfo, altConn);
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

}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;