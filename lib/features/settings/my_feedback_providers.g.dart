// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_feedback_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本人提交过的意见反馈, 信息有误和举报, 新提交的在前.

@ProviderFor(MyFeedbackCases)
final myFeedbackCasesProvider = MyFeedbackCasesProvider._();

/// 本人提交过的意见反馈, 信息有误和举报, 新提交的在前.
final class MyFeedbackCasesProvider
    extends $AsyncNotifierProvider<MyFeedbackCases, FeedbackCasePages> {
  /// 本人提交过的意见反馈, 信息有误和举报, 新提交的在前.
  MyFeedbackCasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myFeedbackCasesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myFeedbackCasesHash();

  @$internal
  @override
  MyFeedbackCases create() => MyFeedbackCases();
}

String _$myFeedbackCasesHash() => r'03bcc8781cf9272075510e9f563783584deb130c';

/// 本人提交过的意见反馈, 信息有误和举报, 新提交的在前.

abstract class _$MyFeedbackCases extends $AsyncNotifier<FeedbackCasePages> {
  FutureOr<FeedbackCasePages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<FeedbackCasePages>, FeedbackCasePages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeedbackCasePages>, FeedbackCasePages>,
              AsyncValue<FeedbackCasePages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 本人提交过的一条记录及其处理结果.

@ProviderFor(feedbackCase)
final feedbackCaseProvider = FeedbackCaseFamily._();

/// 本人提交过的一条记录及其处理结果.

final class FeedbackCaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<FeedbackCase>,
          FeedbackCase,
          FutureOr<FeedbackCase>
        >
    with $FutureModifier<FeedbackCase>, $FutureProvider<FeedbackCase> {
  /// 本人提交过的一条记录及其处理结果.
  FeedbackCaseProvider._({
    required FeedbackCaseFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'feedbackCaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedbackCaseHash();

  @override
  String toString() {
    return r'feedbackCaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FeedbackCase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FeedbackCase> create(Ref ref) {
    final argument = this.argument as int;
    return feedbackCase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedbackCaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedbackCaseHash() => r'631da3e43ecc39cf74560170a61ed5254b793154';

/// 本人提交过的一条记录及其处理结果.

final class FeedbackCaseFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FeedbackCase>, int> {
  FeedbackCaseFamily._()
    : super(
        retry: null,
        name: r'feedbackCaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 本人提交过的一条记录及其处理结果.

  FeedbackCaseProvider call(int id) =>
      FeedbackCaseProvider._(argument: id, from: this);

  @override
  String toString() => r'feedbackCaseProvider';
}
