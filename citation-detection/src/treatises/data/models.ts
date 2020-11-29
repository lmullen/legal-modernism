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