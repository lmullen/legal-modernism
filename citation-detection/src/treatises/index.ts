import CitationRepo from "./data/citationRepo";
import TreatiseRepo from "./data/treatiseRepo";
import BookInfoRepo from "./data/BookInfoRepo";
import { Citation, Treatise } from './data/models';

export async function incrementCitation(guid: string, psmid: string) {
    let c = await CitationRepo.getCitation(psmid, guid);

    if (!c) {
        let newCitation = new Citation();
        newCitation.guid = guid;
        newCitation.psmid = psmid;
        newCitation.count = 0;
        await CitationRepo.insertCitation(newCitation);
        c = await CitationRepo.getCitation(psmid, guid);
    }

    c.count = c.count + 1;
    await CitationRepo.updateCitationCount(c.id, c.count);
}

async function createTreatiseRecord(psmid: string, link: string) {

}

//Creates db entry for treatise if one does not exist yet
export async function createTreatiseEntry(psmid: string) {
    let t = new Treatise();
    t.psmid = psmid;
    t.link = "bomb.com";
    t.year = 1897;
    await TreatiseRepo.createTreatise(t);
    // let t = await TreatiseRepo.getTreatise(psmid);

    // console.log("oh hello");
    // console.log(t);

    // if(!t) {
    //     let bookInfo = await BookInfoRepo.getBookInfo(psmid);

    //     console.log(bookInfo);

    //     t = new Treatise();
    //     t.psmid = psmid;
    //     t.link = bookInfo.productlink;

    //     let year = bookInfo.pubdateYear || bookInfo.pubdateComposed;
    //     t.year = year;
    //     console.log(t);

    //     await TreatiseRepo.createTreatise(t);
    // }
}

export async function markTreatiseProcessed(psmid: string) {

}