import * as _ from "lodash";

import reporterList from './reporters';

export async function getReporterByID(id: number) {
    return _.find(reporterList, (r) => {r.caseDotLawID == id});
}
