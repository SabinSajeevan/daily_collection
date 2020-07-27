class Customer {
  Customer(
      {this.customer_id,
      this.name,
      this.address,
      this.phone,
      this.mobile,
      this.code,
      this.company_id,
      this.created_at});

  String customer_id,
      name,
      address,
      phone,
      mobile,
      code,
      created_at,
      company_id;

  factory Customer.fromJson(Map value) {
    return Customer(
        customer_id: value['customer_id'],
        name: value['name'],
        address: value['address'],
        phone: value['phone'],
        mobile: value['mobile'],
        code: value['code'],
        company_id: value['company_id'],
        created_at: value['created_at']);
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customer_id,
      'name': name,
      'address': address,
      'phone': phone,
      'mobile': mobile,
      'code': code,
      'company_id': company_id,
      'created_at': created_at
    };
  }
}