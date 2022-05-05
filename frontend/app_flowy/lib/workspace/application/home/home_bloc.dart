import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/workspace/application/edit_pannel/edit_context.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart' show CurrentWorkspaceSetting;
import 'package:flowy_sdk/protobuf/flowy-user-data-model/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserListener _listener;

  HomeBloc(UserProfile user, CurrentWorkspaceSetting workspaceSetting)
      : _listener = UserListener(user: user),
        super(HomeState.initial(workspaceSetting)) {
    on<HomeEvent>((event, emit) async {
      await event.map(
        initial: (_Initial value) {
          _listener.start(
            onAuthChanged: (result) {
              _authDidChanged(result);
            },
            onWorkspaceSettingUpdated: (result) {
              result.fold(
                (setting) => add(HomeEvent.didReceiveWorkspaceSetting(setting)),
                (r) => Log.error(r),
              );
            },
          );
        },
        showLoading: (e) async {
          emit(state.copyWith(isLoading: e.isLoading));
        },
        setEditPannel: (e) async {
          emit(state.copyWith(pannelContext: some(e.editContext)));
        },
        dismissEditPannel: (value) async {
          emit(state.copyWith(pannelContext: none()));
        },
        forceCollapse: (e) async {
          emit(state.copyWith(forceCollapse: e.forceCollapse));
        },
        didReceiveWorkspaceSetting: (_DidReceiveWorkspaceSetting value) {
          emit(state.copyWith(workspaceSetting: value.setting));
        },
        unauthorized: (_Unauthorized value) {
          emit(state.copyWith(unauthorized: true));
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _authDidChanged(Either<Unit, FlowyError> errorOrNothing) {
    errorOrNothing.fold((_) {}, (error) {
      if (error.code == ErrorCode.UserUnauthorized.value) {
        add(HomeEvent.unauthorized(error.msg));
      }
    });
  }
}

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.initial() = _Initial;
  const factory HomeEvent.showLoading(bool isLoading) = _ShowLoading;
  const factory HomeEvent.forceCollapse(bool forceCollapse) = _ForceCollapse;
  const factory HomeEvent.setEditPannel(EditPannelContext editContext) = _ShowEditPannel;
  const factory HomeEvent.dismissEditPannel() = _DismissEditPannel;
  const factory HomeEvent.didReceiveWorkspaceSetting(CurrentWorkspaceSetting setting) = _DidReceiveWorkspaceSetting;
  const factory HomeEvent.unauthorized(String msg) = _Unauthorized;
}

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    required bool isLoading,
    required bool forceCollapse,
    required Option<EditPannelContext> pannelContext,
    required CurrentWorkspaceSetting workspaceSetting,
    required bool unauthorized,
  }) = _HomeState;

  factory HomeState.initial(CurrentWorkspaceSetting workspaceSetting) => HomeState(
        isLoading: false,
        forceCollapse: false,
        pannelContext: none(),
        workspaceSetting: workspaceSetting,
        unauthorized: false,
      );
}
