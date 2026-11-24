-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL


EXPERIMENT 1
TITLE: ER Model for an Indian E-Commerce Platform

AIM:
Design an ER model with Customer, Product, Order, OrderItem,
Seller, Category, Payment, Delivery and Address.

1. ENTITY AND ATTRIBUTE DICTIONARY

CUSTOMER
    Primary Key: customer_id
    Attributes: first_name, last_name, email
    Multivalued Attribute: phone

ADDRESS
    Primary Key: address_id
    Attributes: street, city, state, pincode
    Foreign Key: customer_id

SELLER
    Primary Key: seller_id
    Attributes: seller_name, GSTIN (Unique)

CATEGORY
    Primary Key: category_id
    Attributes: category_name

PRODUCT
    Primary Key: product_id
    Attributes: title, price, product_type
    Foreign Keys: seller_id, category_id

CUSTOMERORDER
    Primary Key: order_id
    Attributes: placed_at
    Foreign Keys: customer_id, address_id

ORDERITEM
    Composite Primary Key: (order_id, line_no)
    Attributes: product_id, quantity, unit_price
    Weak Entity: Identified through its Order

PAYMENT
    Primary Key: payment_id
    Attributes: method, amount, status, reference_no
    Foreign Key: order_id

DELIVERY
    Primary Key: delivery_id
    Attributes: tracking_no, status
    Foreign Key: order_id


2. SPECIAL ATTRIBUTES

COMPOSITE ATTRIBUTE:
    Customer Name = first_name + last_name
    Address = street + city + state + pincode

MULTIVALUED ATTRIBUTE:
    Customer phone numbers can have multiple values.
    They are represented separately through CustomerPhone.

WEAK ENTITY:
    OrderItem depends on CustomerOrder.
    Partial Key: line_no
    Complete Key: (order_id, line_no)


3. PRODUCT SPECIALIZATION

PRODUCT ISA:
    Electronics
        Attribute: warranty_months

    Clothing
        Attributes: size_label, fabric

Specialization Type:
    Total and Disjoint

Total:
    Every Product must belong to one subtype.

Disjoint:
    A Product cannot belong to both subtypes.


4. RELATIONSHIPS AND CARDINALITIES

CUSTOMER - CUSTOMERORDER
    One Customer can place 0 to many Orders.
    Each Order belongs to exactly one Customer.

CUSTOMER - ADDRESS
    One Customer can have 0 to many Addresses.
    Each Address belongs to exactly one Customer.

CUSTOMERORDER - ADDRESS
    Each Order uses exactly one saved Address.
    One Address can be used by many Orders.

CUSTOMERORDER - ORDERITEM
    One Order contains 1 to many OrderItems after checkout.
    Each OrderItem belongs to exactly one Order.

PRODUCT - ORDERITEM
    One Product can appear in 0 to many OrderItems.
    Each OrderItem refers to exactly one Product.

SELLER - PRODUCT
    One Seller can list 0 to many Products.
    Each Product belongs to exactly one Seller.

CATEGORY - PRODUCT
    One Category can contain 0 to many Products.
    A Product can belong to 0 or 1 Category.

CUSTOMERORDER - PAYMENT
    One Order can have 0 to many Payment attempts.
    Each Payment belongs to exactly one Order.

CUSTOMERORDER - DELIVERY
    One Order can have 0 or 1 Delivery.
    Each Delivery belongs to exactly one Order.


5. RESULT

The ER model represents all nine requested entities.
It includes primary keys, composite attributes, multivalued
attributes, weak entities, specialization, and participation
constraints.

