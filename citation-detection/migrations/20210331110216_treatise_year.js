
exports.up = function(knex) {
   return knex.schema.table('treatise', (table) => {
        table.integer("year");
    });
};

exports.down = function(knex) {
      return knex.schema.table('treatise', (table) => {
        table.dropColumns("year");
    });
};
