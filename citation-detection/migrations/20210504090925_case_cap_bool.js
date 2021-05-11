
exports.up = function(knex) {
   return knex.schema.table('caseTable', (table) => {
        table.boolean("exists_on_cap");
    });
};

exports.down = function(knex) {
      return knex.schema.table('caseTable', (table) => {
        table.dropcolumns("exists_on_cap");
    });
};


