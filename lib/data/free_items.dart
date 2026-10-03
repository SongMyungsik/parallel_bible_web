/// 무료로 볼 수 있는 범위. (나머지는 "전체 열기"를 구매하면 열림)
///  - 성경 읽기: 전부 무료 (여기서 다루지 않음)
///  - 복음서 병행·구약 인용: 생애 단계 "탄생과 준비"(section 1)
///  - 복음서 병행의 대표 사건 몇 개 (맛보기)
/// 범위를 넓히거나 좁히려면 이 파일만 고치면 됩니다.
library;

/// 무료로 여는 생애 단계 (1 = 탄생과 준비)
const int freeSection = 1;

/// 단계와 상관없이 무료로 여는 복음서 병행 사건 id
///  7 = 오천 명을 먹이심, 68 = 마지막 만찬
const Set<int> freeParallelIds = {7, 68};

/// 이 묶음이 무료 범위인지
bool isFreeItem({required int id, required int section}) =>
    section == freeSection || freeParallelIds.contains(id);
