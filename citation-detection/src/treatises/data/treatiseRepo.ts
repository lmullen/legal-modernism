import * as _ from "lodash";

import Repository from "../../infrastructure/data/BaseDataManager";
import { BookInfo } from './models';

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

    }
}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;