const {Sequelize} = require("sequelize");
const seq = new Sequelize("postgresql://smartmaintenance:Keep0ut2026!@localhost:5432/smartmaintenance_db", {logging:false});
(async()=>{
  const [cols] = await seq.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'technician_profiles' ORDER BY ordinal_position");
  console.log("=== COLONNES technician_profiles ===");
  cols.forEach(c => console.log(c.column_name));
  console.log("");
  const [techs] = await seq.query("SELECT tp.user_id, u.first_name, u.last_name, u.email FROM technician_profiles tp LEFT JOIN users u ON tp.user_id = u.id ORDER BY tp.user_id");
  console.log("=== TECHNICIENS ===");
  techs.forEach(t => console.log(t.user_id + " | " + t.first_name + " " + t.last_name + " | " + t.email));
  await seq.close();
})();
