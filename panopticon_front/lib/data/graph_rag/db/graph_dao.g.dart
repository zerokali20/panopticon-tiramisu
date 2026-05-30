// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_dao.dart';

// ignore_for_file: type=lint
mixin _$GraphDaoMixin on DatabaseAccessor<PanopticonDatabase> {
  $EntitiesTable get entities => attachedDatabase.entities;
  $IdentifiersTable get identifiers => attachedDatabase.identifiers;
  $RelationshipsTable get relationships => attachedDatabase.relationships;
  GraphDaoManager get managers => GraphDaoManager(this);
}

class GraphDaoManager {
  final _$GraphDaoMixin _db;
  GraphDaoManager(this._db);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db.attachedDatabase, _db.entities);
  $$IdentifiersTableTableManager get identifiers =>
      $$IdentifiersTableTableManager(_db.attachedDatabase, _db.identifiers);
  $$RelationshipsTableTableManager get relationships =>
      $$RelationshipsTableTableManager(_db.attachedDatabase, _db.relationships);
}
