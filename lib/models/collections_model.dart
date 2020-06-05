class Collection {
  Collection(
      {this.uuid,
        this.sub_type,
        this.amount,
        this.collection_type_name,
        this.company_name,
        this.customer_name,
        this.created_at
      });
  String uuid, sub_type, amount, collection_type_name,company_name,customer_name,created_at;

  factory Collection.fromJson(Map value) {
    return Collection(
        uuid: value['uuid'],
        sub_type: value['sub_type'],
        amount: value['amount'],
        collection_type_name: value['collection_type_name'],
        company_name: value['company_name'],
        customer_name: value['customer_name'],
        created_at: value['created_at']);
  }
}