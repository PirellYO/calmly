import 'dart:async';
import 'dart:developer' as developer;
import 'package:calmly/src/config/app_state.dart';
import 'package:calmly/src/utils/system_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';

import 'package:calmly/src/bloc/breathe/breathe_bloc.dart';
import 'package:calmly/src/bloc/breathe/breathe_counter_bloc.dart';
import 'package:calmly/src/bloc/breathe/breathe_counter_event.dart';
import 'package:calmly/src/bloc/breathe/breathe_event.dart';
import 'package:calmly/src/components/gradient_background.dart';
import 'package:calmly/src/components/white_line.dart';
import 'package:calmly/src/bloc/calm_box/calm_box_bloc.dart';
import 'package:calmly/src/bloc/calm_box/calm_box_event.dart';
import 'package:calmly/src/screens/congrats_screen.dart';
import 'package:calmly/src/utils/local_db.dart';
import 'package:calmly/src/constants/constants.dart';
import 'package:calmly/src/config/device_config.dart';

class TraditionalCalmBox extends StatefulWidget {
  @override
  _TraditionalCalmBoxState createState() => _TraditionalCalmBoxState();
}

class _TraditionalCalmBoxState extends State<TraditionalCalmBox>
    with SingleTickerProviderStateMixin {
  late StreamSubscription _breatheCounterSubscription;
  late StreamSubscription _calmBoxSubscription;
  late CalmBoxBloc _calmBoxBloc;
  late AnimationController _animationController;
  double radius = 0.55;
  late BreatheBloc _breatheBloc;
  late BreatheCounterBloc _breatheCounterBloc;
  late int lastBreatheCount;
  var lastCalmBoxEvent;
  bool hasStarted = false;
  late AppState _appState;
  late bool isDark;
  bool isCancel = false;

  @override
  void initState() {
    super.initState();
    initController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calmBoxBloc = Provider.of<CalmBoxBloc>(context);
    _breatheBloc = Provider.of<BreatheBloc>(context);
    _breatheCounterBloc = Provider.of<BreatheCounterBloc>(context);
    _appState = Provider.of<AppState>(context);
    isDark = SystemTheme.isDark(_appState);
  }

  void initController() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 4000),
        vsync: this,
        lowerBound: 0.55,
        upperBound: 0.95)
      ..addStatusListener((AnimationStatus animationStatus) {
        print('Animation Status : $animationStatus');
        if (animationStatus == AnimationStatus.forward ||
            animationStatus == AnimationStatus.reverse) {
          _calmBoxBloc.calmBoxEventSink.add(BusyCalmBoxEvent());
          // _breatheBloc.inBreatheEvent.add(HoldBreatheEvent());
        } else if (animationStatus == AnimationStatus.completed) {
          _calmBoxBloc.calmBoxEventSink.add(CompletedExpandCalmBoxEvent());

          _breatheBloc.inBreatheEvent.add(IdleEvent());
        } else if (animationStatus == AnimationStatus.dismissed) {
          print('Last CalmBoxEvent : $lastCalmBoxEvent');
          if (lastCalmBoxEvent == CalmBox.completedExpand) {
            _breatheBloc.inBreatheEvent.add(IdleEvent());
          } else {
            _calmBoxBloc.calmBoxEventSink.add(CompletedShrinkCalmBoxEvent());
            _breatheBloc.inBreatheEvent.add(IdleEvent());
          }
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: height * 0.24,
          child: Container(
            width: width,
            height: height * 0.47,
            child: Stack(
              children: [
                GradientBackground(
                  colors: [],
                ),
                Positioned(
                  top: height * 0.24,
                  child: DividerLine(
                    height: height * 0.0039,
                    width: width,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  top: height * 0.2755, //28
                  child: DividerLine(
                    height: height * 0.01,
                    width: width,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  top: height * 0.31, //32
                  child: DividerLine(
                    height: height * 0.017,
                    width: width,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  top: height * 0.345,
                  child: DividerLine(
                    height: height * 0.018,
                    width: width,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  top: height * 0.38,
                  child: DividerLine(
                    height: height * 0.028,
                    width: width,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  top: height * 0.42,
                  child: DividerLine(
                    height: height * 0.03,
                    width: width,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder(
          initialData: CalmBox.shrink,
          stream: _calmBoxBloc.outCalmBox,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            CalmBox calmBox = snapshot.data;
            if (calmBox == CalmBox.stop) {
              _animationController.duration = const Duration(milliseconds: 250);
              _animationController.stop();
            }
            return GestureDetector(
              onTap: () => handleTap(calmBox),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                  BlendMode.srcOut,
                ), // This one will create the magic
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ), // This one will handle background + difference out
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (_, __) {
                          return Container(
                            height: width * _animationController.value,
                            width: width * _animationController.value,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(width * 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void handleTap(CalmBox calmBox) {
    if (calmBox != CalmBox.busy) {
      HapticFeedback.heavyImpact();
      startCalmly();
      hasStarted = true;
    }
  }

  vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 70);
    }
  }

  exhale() {
    developer.log('Exhale');
    if (_appState.isVibrationOn) {
      vibrate();
    }
    _calmBoxBloc.calmBoxEventSink.add(ShrinkCalmBoxEvent());
    _breatheBloc.inBreatheEvent.add(ExhaleEvent());
    _animationController.duration = const Duration(milliseconds: 8000); //8000
    _animationController.reverse();
  }

  inhale() {
    developer.log('Inhale');
    if (_appState.isVibrationOn) {
      vibrate();
    }
    _calmBoxBloc.calmBoxEventSink.add(ExpandCalmBoxEvent());
    _breatheBloc.inBreatheEvent.add(InhaleEvent());
    _animationController.duration = const Duration(milliseconds: 4000); //4000
    _animationController.forward();
  }

  startCalmly() {
    inhale();
    if (!hasStarted) {
      // don't listen if we are already listening

      _breatheCounterSubscription =
          _breatheCounterBloc.outBreatheCounter.listen(mapBreatheCount);
      _calmBoxSubscription = _calmBoxBloc.outCalmBox.listen(mapCalmBoxEvent);
    }
  }

  mapCalmBoxEvent(calmBoxValue) {
    lastCalmBoxEvent = calmBoxValue;
    if (calmBoxValue == CalmBox.cancel) {
      _animationController.duration = const Duration(milliseconds: 200);
      _animationController.animateTo(_animationController.lowerBound);
      // Future.delayed(Duration(milliseconds: 100), () {
      //   isCancel = false;
      // });
      print('Animation Controller value: ${_animationController.value}');
    } else if (calmBoxValue == CalmBox.completedExpand) {
      _breatheBloc.inBreatheEvent.add(HoldBreatheEvent());
      Future.delayed(const Duration(milliseconds: 7000), () {
        // 7000
        exhale();
      });
    } else if (calmBoxValue == CalmBox.completedShrink) {
      _breatheCounterBloc.inBreatheCounterEvent.add(OneBreatheCounterEvent());
    }
  }

  mapBreatheCount(breatheCount) {
    lastBreatheCount = breatheCount;
    if (breatheCount == 0) {
      stopCalmly();
    } else if (breatheCount == -1) {
      cancelCalmly();
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        inhale();
      });
    }
  }

  stopCalmly() {
    _calmBoxBloc.calmBoxEventSink.add(StopCalmBoxEvent());
    _breatheCounterBloc.inBreatheCounterEvent
        .add(CompletedBreatheCounterEvent());

    _breatheBloc.inBreatheEvent.add(IdleEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCongratsScreen();
    });
  }

  cancelCalmly() {
    isCancel = true;
    _calmBoxBloc.calmBoxEventSink.add(CancelCalmBoxEvent());
    _breatheCounterBloc.inBreatheCounterEvent
        .add(CompletedBreatheCounterEvent());

    _breatheBloc.inBreatheEvent.add(IdleEvent());
  }

  @override
  void dispose() {
    // _calmBoxBloc.dispose();
    // _breatheBloc.dispose();
    // _breatheCounterBloc.dispose();
    _breatheCounterSubscription.cancel();
    _calmBoxSubscription.cancel();
    super.dispose();
  }

  showCongratsScreen() {
    LocalDB localDB = LocalDB();
    int count = localDB.getTotalCalmly ?? 0;
    localDB.saveTotalCalmly(++count);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CongratsScreen(),
      ),
    );
  }
}
