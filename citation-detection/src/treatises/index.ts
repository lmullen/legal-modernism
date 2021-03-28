import CitationRepo from "./data/citationRepo";
import { Citation } from './data/models';

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