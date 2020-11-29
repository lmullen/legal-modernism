import Repository from "../../infrastructure/data/BaseDataManager";
import { PageOCRText } from './models';

class OcrRepo extends Repository {
    constructor() {
        super(PageOCRText);
    }

    async getOCRTextByTreatiseID(treatiseID: string) {
        const sql = `select * from page_ocrtext where psmid = ?`;
        return this.rawQuery(sql, [treatiseID]);
    }

}

const instance = new OcrRepo();
Object.seal(instance);
export default instance;