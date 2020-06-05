class Company {
  Company(
      {this.uuid,
        this.name
      });
  String uuid,name;

  factory Company.fromJson(Map value) {
    return Company(
        uuid: value['uuid'],
        name: value['name']);
  }
}