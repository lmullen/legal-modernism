import Repository from "../../infrastructure/data/Repository";
import { PageOCRText } from './models';

class OcrRepo extends Repository {
    constructor() {
        super(PageOCRText);
    }

    async getOCRTextByTreatiseID(treatiseID: string) {
        const sql = `select * from moml.page_ocrtext where psmid = ? ORDER BY pageid asc`;
        return this.rawQuery(sql, [treatiseID]);
    }

}

const instance = new OcrRepo();
Object.seal(instance);
export default instance;