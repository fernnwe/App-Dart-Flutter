import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Para codificar y decodificar los productos

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Facturación e Inventario',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Product> products = [];
  double totalFactura = 0.0;
  String? clientName;
  int? editingIndex;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController clientController = TextEditingController();

  // Lista de productos predefinidos para seleccionar
  final List<Product> predefinedProducts = [
    Product(name: 'Producto A', price: 10.0),
    Product(name: 'Producto B', price: 20.0),
    Product(name: 'Producto C', price: 30.0),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Cargar productos desde shared_preferences
  void _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsData = prefs.getString('products');
    if (productsData != null) {
      final List<dynamic> decodedData = json.decode(productsData);
      setState(() {
        products = decodedData.map((item) => Product.fromJson(item)).toList();
        totalFactura = _calculateTotal();
      });
    }
  }

  // Guardar productos en shared_preferences
  void _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(products.map((e) => e.toJson()).toList());
    prefs.setString('products', encodedData);
  }

  void _addProduct() {
    String name = nameController.text.trim();
    double? price = double.tryParse(priceController.text);

    if (name.isNotEmpty && price != null && price > 0) {
      setState(() {
        if (editingIndex != null) {
          // Editar producto existente
          products[editingIndex!] = Product(name: name, price: price);
        } else {
          // Agregar nuevo producto
          products.add(Product(name: name, price: price));
        }
        totalFactura = _calculateTotal();
      });
      _saveProducts(); // Guardar productos después de agregar uno nuevo
      nameController.clear();
      priceController.clear();
      editingIndex = null;
    } else {
      _showErrorDialog('Ingrese un nombre y precio válido.');
    }
  }

  void _removeProduct(int index) {
    setState(() {
      totalFactura -= products[index].price;
      products.removeAt(index);
      _saveProducts(); // Guardar productos después de eliminar uno
    });
  }

  void _addClient() {
    String name = clientController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        clientName = name;
      });
      clientController.clear();
    } else {
      _showErrorDialog('Ingrese el nombre del cliente.');
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var product in products) {
      total += product.price;
    }
    return total;
  }

  void _editProduct(int index) {
    setState(() {
      editingIndex = index;
      nameController.text = products[index].name;
      priceController.text = products[index].price.toString();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturación e Inventario'),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientSection(),
              const SizedBox(height: 20),
              _buildProductForm(),
              const SizedBox(height: 20),
              _buildPredefinedProductList(),
              const SizedBox(height: 20),
              _buildProductList(),
              const SizedBox(height: 20),
              _buildInvoiceSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: clientController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addClient,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
              child: const Text('Guardar'),
            ),
          ],
        ),
        if (clientName != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Cliente: $clientName', style: const TextStyle(fontSize: 18)),
          ),
      ],
    );
  }

  Widget _buildProductForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Agregar Producto:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Producto',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Precio del Producto',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addProduct,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
          child: Text(editingIndex == null ? 'Agregar Producto' : 'Actualizar Producto'),
        ),
      ],
    );
  }

  Widget _buildPredefinedProductList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Seleccionar Producto Predefinido:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          itemCount: predefinedProducts.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(predefinedProducts[index].name),
              subtitle: Text('Precio: \$${predefinedProducts[index].price.toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    products.add(predefinedProducts[index]);
                    totalFactura = _calculateTotal();
                    _saveProducts(); // Guardar productos después de agregar uno nuevo
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Productos:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(products[index].name),
              subtitle: Text('Precio: \$${products[index].price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editProduct(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeProduct(index),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInvoiceSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Total Factura: \$${totalFactura.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }
}

class Product {
  final String name;
  final double price;

  Product({required this.name, required this.price});

  // Método para convertir un producto a un mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }

  // Método para crear un producto desde un mapa (JSON)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      price: json['price'],
    );
  }
}
