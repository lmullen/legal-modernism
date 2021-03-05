import TreatiseRepo from "./data/treatiseRepo";
import { Citation } from './data/models';

export async function incrementCitation(guid: string, psmid: string) {
   let c = await TreatiseRepo.getCitation(psmid, guid); 

   if (!c) {
       let newCitation = new Citation();
       newCitation.guid = guid;
       newCitation.psmid = psmid;
       c = await TreatiseRepo.insertCitation
   }

   c.count = c.count + 1;

   await TreatiseRepo.updateCitationCount(c.id, c.count);
}