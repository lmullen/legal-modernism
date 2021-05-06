import * as _ from "lodash";

import Repository from "../../infrastructure/data/Repository";
import { CONN } from "../../infrastructure/data/knexProvider";
import { BookInfo, Citation, Treatise } from './models';

/** vestigal from when there were 2 databases */
class BookInfoRepo extends Repository {
    constructor() {
        super(BookInfo);
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

    async getBookInfo(psmid: string) {
        const sql = `select * from moml.book_info where psmid = '${psmid}'`;
        return this.rawQuery(sql)
            .then((res) => {
                return res[0] || null;
            });
    }

    async getAllTreatises() {
        const sql = `select * from moml.book_info`;
        return this.rawQuery(sql)
            // .then((res) => {
            //     return res[0] || null;
            // });
    }
}

const instance = new BookInfoRepo();
Object.seal(instance);
export default instance;