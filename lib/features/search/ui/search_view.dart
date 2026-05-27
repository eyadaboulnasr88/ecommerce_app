import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecommerce_app/core/model/product_model.dart';
import 'package:ecommerce_app/features/search/cubit/search_cubit.dart';
import 'package:ecommerce_app/features/search/cubit/search_state.dart';
import 'package:ecommerce_app/features/product/details_product_view.dart';

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
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            cubit.searchProducts(value);
          },
        ),
      ),

      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return const Center(child: Text('Start typing to search'));
          } else if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SearchLoaded) {
            if (state.results.isEmpty) {
              return const Center(child: Text('No products found'));
            }

            return ListView.builder(
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final ProductModel product = state.results[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsProductView(product: product),
                      ),
                    );
                  },

                  child: ListTile(
                    leading: Image.network(
                      product.image,
                      width: 60,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                    ),

                    title: Text(product.title),

                    subtitle: Text('\$${product.price.toString()}'),
                  ),
                );
              },
            );
          } else if (state is SearchError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}
