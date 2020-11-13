import BaseDataModel from '../../infrastructure/data/BaseDataModel';

export class pageOCRText extends BaseDataModel {
    static tableName = "page_ocrtext";

    pageid: string
    psmid: string
    ocrtext: string
} 