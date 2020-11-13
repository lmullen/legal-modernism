import Repository from "../../infrastructure/data/BaseDataManager";
import { pageOCRText } from './models';

class TreatiseRepo extends Repository {
    constructor() {
        super(pageOCRText);
    }

    async getByTreatiseID(treatiseID: string) {
        const sql = `select * from page_ocrtext where psmid = ?`;
        return this.rawQuery(sql, [treatiseID]);
    }
}

const instance = new TreatiseRepo();
Object.seal(instance);
export default instance;