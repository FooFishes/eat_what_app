/// 一页列表数据, 由接口的 `PageResult` 转换而来. [page] 从 1 开始.
///
/// [total] 是全部条目数, 接口没有给出时为 null.
class const Paged<T>({
  required final List<T> items,
  final int page = 1,
  final bool hasNext = false,
  final int? total,
}) {
  const Paged.empty() : this(items: const []);

  /// 把 [next] 的条目追加到当前条目之后, 并采用 [next] 的分页状态.
  Paged<T> append(Paged<T> next) => Paged(
    items: [...items, ...next.items],
    page: next.page,
    hasNext: next.hasNext,
    total: next.total ?? total,
  );
}
