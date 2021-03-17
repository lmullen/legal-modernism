exports.up = function (knex, Promise) {
    return knex.schema.table('caseTable', (table) => {
        table.integer("year");
    });
};

exports.down = function (knex, Promise) {
    return knex.schema.table('caseTable', (table) => {
        table.dropColumns("year");
    });
};
