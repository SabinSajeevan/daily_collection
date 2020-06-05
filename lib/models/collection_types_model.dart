class CollectionType {
  CollectionType(
      {this.uuid,
        this.type,
        this.sub_type
      });
  String uuid, type, sub_type;

  factory CollectionType.fromJson(Map value) {
    return CollectionType(
        uuid: value['uuid'],
        type: value['type'],
        sub_type: value['sub_type']);
  }
}