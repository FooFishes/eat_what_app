/// 一页列表：接口的 `PageResult` 转过来，[page] 从 1 开始。
class const Paged<T>({
  required final List<T> items,
  final int page = 1,
  final bool hasNext = false,
}) {
  const Paged.empty() : this(items: const []);

  /// 把下一页接在后面。
  Paged<T> append(Paged<T> next) => Paged(
    items: [...items, ...next.items],
    page: next.page,
    hasNext: next.hasNext,
  );
}
