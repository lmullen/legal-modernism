import BaseDataModel from '../../infrastructure/data/BaseDataModel';

export class PageOCRText extends BaseDataModel {
    static tableName = "page_ocrtext";

    pageid: string
    psmid: string
    ocrtext: string
} 

export class BookInfo extends BaseDataModel {
    static tableName = "book_info"; //not sure if need to preface with moml

    psmid: string
    contentType: string
    id: string
    pubdate_composed: string
}

export class Citation extends BaseDataModel {
    static tableName = "citation"

    psmid: string
    guid: string
    count: number
}

export class Treatise extends BaseDataModel {
    static tableName = "treatise";

    psmid: string
    link: string
    lastRun: Date
}