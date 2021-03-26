import CitationRepo from "./data/citationRepo";
import { Citation } from './data/models';

export async function incrementCitation(guid: string, psmid: string) {
    let c = await CitationRepo.getCitation(psmid, guid);
    // console.log(c);

    // if (!c) {
    //     console.log("must create!");
    //     let newCitation = new Citation();
    //     newCitation.guid = guid;
    //     newCitation.psmid = psmid;
    //     newCitation.count = 0;
    //     c = await CitationRepo.insertCitation(newCitation);
    // }

    // c.count = c.count + 1;
    // // console.log(c);
    // // console.log('hey updating');

    await CitationRepo.updateCitationCount(c.id, c.count);
}