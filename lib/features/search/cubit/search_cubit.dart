import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/core/model/product_model.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      final q = query[0].toUpperCase() + query.substring(1);
      final snapshot = await _firestore
          .collection('products')
          .where('title', isGreaterThanOrEqualTo: q)
          .where('title', isLessThanOrEqualTo: '$q\uf8ff')
          .get();

      final results = snapshot.docs
          .map(
            (doc) => ProductModel.fromJson(
              doc.data(),
              doc.id,
            ),
          )
          .toList();

      emit(SearchLoaded(results));
    } catch (e) {
      emit(
        SearchError(
          'Search failed: ${e.toString()}',
        ),
      );
    }
  }
}