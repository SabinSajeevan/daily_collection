class Customer {
  Customer(
      {this.customer_id,
        this.name,
        this.address,
        this.phone,
        this.mobile
      });
  String customer_id, name, address, phone,mobile;

  factory Customer.fromJson(Map value) {
    return Customer(
        customer_id: value['customer_id'],
        name: value['name'],
        address: value['address'],
        phone: value['phone'],
        mobile: value['mobile']);
  }

  @override
  String toString() {
    return name;
  }
}