// Diagnóstico HH (B29/B30): erro do job hh_entregas + cobertura do status_usuario.
// Rodar:  Get-Content scripts\diag_hh.js | docker exec -i $ct mongosh Cluster-EasyTek --quiet
const j = db.sap_jobs.find({tipo: "hh_entregas"}).sort({criado_em: -1}).limit(1).toArray()[0];
print("=== hh_entregas — ultimo job ===");
print("status = " + (j ? j.status : "nenhum"));
if (j) {
  print("erro:");
  printjson(j.erro);
  print("resultado:");
  printjson(j.resultado);
}
print("");
print("=== status_usuario no sap_backlog ===");
print("com status_usuario: " + db.sap_backlog.countDocuments({status_usuario: {$ne: null}}));
print("sem (null):         " + db.sap_backlog.countDocuments({status_usuario: null}));
print("total:              " + db.sap_backlog.countDocuments({}));
print("");
print("=== distintos USTXT (codigo -> quantidade) ===");
db.sap_backlog.aggregate([
  {$match: {status_usuario: {$ne: null}}},
  {$group: {_id: "$status_usuario", n: {$sum: 1}}},
  {$sort: {n: -1}}
]).forEach(d => printjson(d));
