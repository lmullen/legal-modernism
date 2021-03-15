exports.up = function (knex) {
    return knex.schema.createTableIfNotExists('caseTable', (t) => {
        t.increments();
        t.string('full_name');
        t.string('short_name');
        t.string('guid');
        t.integer('case_dot_law_id');
    });
};

exports.down = function (knex) {
    return knex.schema.dropTableIfExists('caseTable');
};
