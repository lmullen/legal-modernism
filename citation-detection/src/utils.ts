import * as _ from "lodash";

export function lastItem(array: any[]) {
    return array[array.length - 1];
}

export function camelCase(obj: any) {
    let res = _.mapKeys(obj, (value, key) => {
        return _.camelCase(String(key));
    });

    return res
}