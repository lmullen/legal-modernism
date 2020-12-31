import BaseDataModel from '../../infrastructure/data/BaseDataModel';

export class Case extends BaseDataModel {
    static tableName = "case";

    id: number
    caseDotLawId: number
    fullName: string
    shortName: string
    year: number
    guid: string
}