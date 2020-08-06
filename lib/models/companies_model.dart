class Company {
  Company({this.uuid, this.name, this.agent_id});

  String uuid, name, agent_id;

  factory Company.fromJson(Map value) {
    return Company(
        uuid: value['uuid'], name: value['name'], agent_id: value['agent_id']);
  }
}