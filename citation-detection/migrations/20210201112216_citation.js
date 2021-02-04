
exports.up = function(knex) {
    return knex.schema.createTableIfNotExists('citation', (citationTable) => {
        citationTable.increments();
        citationTable.string('psmid');
        citationTable.string('guid');
        citationTable.integer('count');
        // userTable.timestamps();
    });

};

exports.down = function(knex) {
    return knex.schema.dropTableIfExists('citation');
};
