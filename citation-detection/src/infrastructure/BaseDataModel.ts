// <reference path="../../../typeDecs/objection.d.ts" />

import {Model} from "objection";
import * as _ from "lodash";

/*http://vincit.github.io/objection.js/#map-column-names-to-different-property-names*/
export default class BaseBloomtriModel extends Model {
    readonly id: number;
    $formatDatabaseJson(json) {
        // Call superclass implementation.
        json = super.$formatDatabaseJson.call(this, json);

        return _.mapKeys(json, function (value, key) {
            return _.snakeCase(String(key));
        });
    }

    $parseDatabaseJson(json) {
        json = _.mapKeys(json, function (value, key) {
            return _.camelCase(String(key));
        });

        // Call superclass implementation.
        return super.$parseDatabaseJson.call(this, json);
    }

}