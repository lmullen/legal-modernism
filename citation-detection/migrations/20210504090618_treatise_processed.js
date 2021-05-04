
exports.up = function(knex) {
   return knex.schema.table('treatise', (table) => {
        table.boolean("processed");
    });
};

exports.down = function(knex) {
      return knex.schema.table('treatise', (table) => {
        table.dropColumns("processed");
    });
};

