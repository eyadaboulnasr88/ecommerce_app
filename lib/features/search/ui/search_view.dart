import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecommerce_app/features/search/cubit/search_cubit.dart';
import 'package:ecommerce_app/features/search/cubit/search_state.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(),
      child: const SearchViewBody(),
    );
  }
}

class SearchViewBody extends StatefulWidget {
  const SearchViewBody({super.key});

  @override
  State<SearchViewBody> createState() => _SearchViewBodyState();
}

class _SearchViewBodyState extends State<SearchViewBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F4),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Search products...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.black54),
            ),
            onChanged: (query) {
              cubit.searchProducts(query);
            },
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return const Center(
              child: Text('Start typing to search'),
            );
          } else if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SearchLoaded) {
            if (state.results.isEmpty) {
              return const Center(child: Text('No products found'));
            }

            return ListView.builder(
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final product = state.results[index];
                return _buildProductCard(product);
              },
            );
          } else if (state is SearchError) {
            return Center(child: Text(state.message));
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return ListTile(
      leading: Image.network(
        product['image'] ?? '',
        width: 60,
        errorBuilder: (_, __, ___) => const Icon(Icons.image),
      ),
      title: Text(product['title'] ?? 'No title'),
      subtitle: Text('\$${product['price'] ?? 0}'),
    );
  }
}