
exports.up = function(knex) {
    return knex.schema.createTableIfNotExists('treatise', (table) => {
        table.increments();
        table.string('psmid');
        table.string('url');
        table.datetime('last_run');
    });
};

exports.down = function(knex) {
    return knex.schema.dropTableIfExists('treatise');
};
