import BaseDataModel from '../../infrastructure/data/BaseDataModel';
import { altConn } from "../../infrastructure/data/connProvider";

export class Case extends BaseDataModel {
    static tableName = "caseTable";

    id: number
    caseDotLawId: number
    fullName: string
    shortName: string
    year: number
    guid: string
}
