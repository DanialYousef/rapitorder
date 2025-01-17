import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proj1/modules/restaurant/restaurant_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/data_model.dart';
import '../../shared/network/local/cache_helper.dart';
import '../../shared/network/remote/dio_helper.dart';

class RestaurantCubit extends Cubit<RestaurantStates>{
  RestaurantCubit() : super(RestaurantInitialState());
  static RestaurantCubit get(context) => BlocProvider.of(context);
  List<DataModel> foodData=[];
  void getFood(){
    DioHelper.getFavoriteFoodData(
      url: '/food/api/v1/favorites',
      query: {
        'X-RapidAPI-Key':'079fc6305emsh023fcbc804f30f7p1671b3jsnb39926bee9fb'
      },
    ).then((value){
      List<dynamic> responseData = value!.data;
      foodData = responseData.map((item) => DataModel.fromJson(item)).toList();
      emit(RestaurantGetFoodSuccessState());
    }
    ).catchError((error){
      print(error.toString());
      emit(RestaurantGetFoodErrorState(error.toString()));
    });
  }
  List<DataModel>favoriteFood = [];
  void moveNews(int index) async {
    emit(NewsGetMoveLoadingState());
    DataModel model = DataModel.fromJson(foodData[index].toMap());
    // Check if the item already exists in the movingNews list
    bool isDuplicate = false;
    for (var news in favoriteFood) {
      if (news.favoriteDish?.toLowerCase() == model.favoriteDish?.toLowerCase()) {
        isDuplicate = true;
        break;
      }
    }
    if (!isDuplicate) {
      //model.isFavorite = true;
      favoriteFood.add(model);
      List<dynamic> jsonList = favoriteFood.map((dataModel) => dataModel.toMap()).toList();
      await preferences.saveJsonList('move', jsonList);
      print('save in sp');
    }
    emit(NewsMovingState());
  }
  void getFromSp() async {
    List<dynamic> savedMovingNews = await preferences.getJsonList('move', []);
    favoriteFood.addAll(savedMovingNews.map((json) => DataModel.fromJson(json)).toList());
    print('moving News is : ') ;
    print(favoriteFood);
    emit(NewsLoadedState());
  }
  void removeFromFavorites(int index) async {
    if (index >= 0 && index < favoriteFood.length) {
      favoriteFood.removeAt(index);
      List<dynamic> jsonList = favoriteFood.map((dataModel) => dataModel.toMap()).toList();
      await preferences.saveJsonList('move', jsonList);
      print('removed from favorites');
    }
  }
  void clearFavorites() async {
    favoriteFood.clear();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('move');
    print('cleared favorites');
  }
}