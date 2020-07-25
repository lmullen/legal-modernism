import * as _ from "lodash";
import * as Q from "q";

export function lastItem(array: any[]) {
    return array[array.length - 1];
}

export function camelCase(obj: any) {
    let res = _.mapKeys(obj, (value, key) => {
        return _.camelCase(String(key));
    });

    return res
}

export function promise<T>(fn, args = []): Q.Promise<T> {
    let promise = Q.defer<T>();

    let callback = (err, data) => {
        if (err) {
            promise.reject(err);
        }

        promise.resolve(data as T);
    }

    fn(...args, callback);

    return promise.promise;
}