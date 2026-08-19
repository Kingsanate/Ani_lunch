import 'admin_api.dart';
import 'api_client.dart';
import 'catalog_api.dart';
import 'orders_api.dart';
import 'riders_api.dart';
import 'token_manager.dart';
import 'users_api.dart';
import 'vendors_api.dart';

/// Facade over every domain API. Construct once per app with a shared
/// [ApiClient] and [TokenManager].
class AnilunchApi {
  final ApiClient client;
  final TokenManager tokens;

  late final CatalogApi catalog;
  late final OrdersApi orders;
  late final UsersApi users;
  late final RidersApi riders;
  late final VendorsApi vendors;
  late final PaymentsApi payments;
  late final AdminApi admin;

  AnilunchApi({required this.client, required this.tokens})
      : catalog = CatalogApi(client),
        orders = OrdersApi(client),
        users = UsersApi(client),
        riders = RidersApi(client),
        vendors = VendorsApi(client),
        payments = PaymentsApi(client),
        admin = AdminApi(client);
}