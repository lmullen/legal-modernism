import * as _ from "lodash";

import reporterList from './reporters';

export async function getReporterByID(id: number) {
    // return _.find(reporterList, (r) => {r.caseDotLawID == id});
    let p = (r) => {
        return r.caseDotLawID == id;
    }

    let filtered = reporterList.filter(p);
    return filtered[0];
}
