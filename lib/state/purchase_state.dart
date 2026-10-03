import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/free_items.dart';
import 'app_settings.dart';

/// "전체 열기" 구매 상태와 Google Play 결제.
///
///  - 무료: 성경 읽기 전체 + 일부 병행·인용 (data/free_items.dart)
///  - 한 번 구매(인앱 상품 [productId])하면 모든 병행·인용이 열림
///
/// 구매 여부는 기기의 DB(app_settings)에 저장해 인터넷 없이도 유지됩니다.
/// 앱을 켤 때 Play 스토어에 구매 내역을 물어, 다시 설치했거나 폰을 바꿔도 자동으로 열립니다.
/// (환불된 구매를 자동으로 다시 잠그지는 않습니다. 구매한 사람이 잘못 잠기는 일을 막기 위해서입니다.)
///
/// Android에서만 결제가 동작합니다. Windows(개발용)에서는 설정 화면의 개발용 스위치로 잠금을 바꿉니다.
class PurchaseState extends ChangeNotifier {
  PurchaseState(this._settings, {bool? storeSupported})
    : storeSupported = storeSupported ?? Platform.isAndroid;

  /// Play Console의 인앱 상품 ID (일회성 제품). 한 번 만들면 바꿀 수 없습니다.
  static const String productId = 'full_unlock';

  final AppSettings _settings;

  /// 이 기기에서 Play 결제를 쓸 수 있는 종류인지 (Android)
  final bool storeSupported;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 스토어에서 받아 온 상품 정보 (가격 표시용). 못 받았으면 null.
  ProductDetails? product;

  /// 결제·복원이 진행 중인지 (버튼을 잠시 막음)
  bool busy = false;

  /// 사용자에게 보여 줄 안내 (예: "구매를 취소했습니다.")
  String? message;

  /// 전체 열기를 구매했는지
  bool get unlocked => _settings.fullUnlocked;

  /// 스토어에 적힌 가격 (예: "₩2,900"). 아직 모르면 null.
  String? get priceLabel => product?.price;

  /// 이 묶음을 지금 열 수 있는지 (무료 범위이거나 구매했으면 true)
  bool canOpen({required int id, required int section}) =>
      unlocked || isFreeItem(id: id, section: section);

  /// 앱을 켤 때 한 번: 결제 알림 듣기 시작 + 상품 정보 + 이전 구매 확인
  Future<void> init() async {
    if (!storeSupported) return;
    try {
      final iap = InAppPurchase.instance;
      _subscription = iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => _finish('결제 알림을 받지 못했습니다. ($e)'),
      );
      if (!await iap.isAvailable()) return;
      await _loadProduct();
      // 이전에 구매했으면 purchaseStream으로 "restored"가 옴 → 자동으로 열림
      if (!unlocked) await iap.restorePurchases();
    } catch (e) {
      debugPrint('구매 준비 실패: $e');
    }
  }

  Future<void> _loadProduct() async {
    final response = await InAppPurchase.instance.queryProductDetails({
      productId,
    });
    if (response.productDetails.isNotEmpty) {
      product = response.productDetails.first;
      notifyListeners();
    }
  }

  /// [전체 열기] 버튼
  Future<void> buy() async {
    if (busy) return;
    if (!storeSupported) {
      _finish('이 기기에서는 구매할 수 없습니다. (Android의 Google Play에서 구매)');
      return;
    }
    _start('Google Play에 연결하는 중…');
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) {
        _finish('Google Play에 연결하지 못했습니다. 인터넷과 Play 스토어를 확인해 주세요.');
        return;
      }
      if (product == null) await _loadProduct();
      final item = product;
      if (item == null) {
        _finish('상품 정보를 받지 못했습니다. 잠시 뒤에 다시 시도해 주세요.');
        return;
      }
      // 결과는 purchaseStream(_onPurchases)으로 옵니다.
      await iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: item),
      );
    } catch (e) {
      _finish('구매를 시작하지 못했습니다. ($e)');
    }
  }

  /// [구매 복원] 버튼: 같은 Google 계정으로 이미 구매했으면 다시 엶
  Future<void> restore() async {
    if (busy) return;
    if (!storeSupported) {
      _finish('이 기기에서는 구매 내역을 확인할 수 없습니다.');
      return;
    }
    _start('구매 내역을 확인하는 중…');
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) {
        _finish('Google Play에 연결하지 못했습니다. 인터넷과 Play 스토어를 확인해 주세요.');
        return;
      }
      await iap.restorePurchases();
      // 구매 내역이 있으면 곧 _onPurchases가 불립니다. 없으면 아무 알림도 오지 않으므로 잠시 기다린 뒤 안내.
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!unlocked) _finish('이 Google 계정의 구매 내역을 찾지 못했습니다.');
    } catch (e) {
      _finish('구매 내역을 확인하지 못했습니다. ($e)');
    }
  }

  /// Play 스토어가 알려 주는 결제 결과
  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          // 편의점 결제 등 아직 돈이 들어오지 않은 상태 → 열지 않음
          _start('결제를 처리하는 중입니다…');
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _settings.setFullUnlocked(true);
          _finish('전체 기능이 열렸습니다. 감사합니다.');
        case PurchaseStatus.canceled:
          _finish('구매를 취소했습니다.');
        case PurchaseStatus.error:
          _finish('구매하지 못했습니다. (${p.error?.message ?? '알 수 없는 오류'})');
      }
      // 구매를 받았다고 Play에 알림. 알리지 않으면 며칠 뒤 자동 환불됩니다.
      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
  }

  // ---- 코드로 열기 (Play 검토자·선물용) ----

  /// 맞는 코드를 변환한 값. 코드 글자를 앱 안에 그대로 두지 않기 위해 변환값만 둡니다.
  /// 새 코드를 더하려면 `codeHash('새코드')` 값을 여기에 추가.
  static const Set<int> _codeHashes = {0xc51c3386};

  /// 코드를 숫자로 변환 (대소문자·띄어쓰기·하이픈 무시). FNV-1a 방식에 앱 고유 글자를 섞음.
  static int codeHash(String code) {
    final text =
        'parallelbible:${code.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '')}';
    var h = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  static bool isValidCode(String code) =>
      code.trim().isNotEmpty && _codeHashes.contains(codeHash(code));

  /// [코드 입력]: 맞으면 전체를 열고 true
  Future<bool> redeemCode(String code) async {
    if (!isValidCode(code)) {
      _finish('코드가 맞지 않습니다. 다시 확인해 주세요.');
      return false;
    }
    await _settings.setFullUnlocked(true);
    _finish('코드가 확인되어 전체 기능이 열렸습니다.');
    return true;
  }

  /// 개발용(Windows 등 결제가 없는 기기): 잠금 상태를 직접 바꿈
  Future<void> setUnlockedForDev(bool value) async {
    await _settings.setFullUnlocked(value);
    message = null;
    notifyListeners();
  }

  /// 안내 문구 지우기 (구매 창을 새로 열 때)
  void clearMessage() {
    if (message == null) return;
    message = null;
    notifyListeners();
  }

  void _start(String text) {
    busy = true;
    message = text;
    notifyListeners();
  }

  void _finish(String text) {
    busy = false;
    message = text;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
