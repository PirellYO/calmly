import 'dart:async';
import 'dart:ui';

import 'package:calmly/src/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:calmly/src/constants/custom_icons_icons.dart';
import 'package:calmly/src/components/calm_box/traditional_calm_box.dart';
import 'package:calmly/src/components/settings_bottom_sheet.dart';
import 'package:calmly/src/bloc/breathe/breathe_bloc.dart';

import 'package:calmly/src/bloc/breathe/breathe_counter_bloc.dart';
import 'package:calmly/src/bloc/breathe/breathe_counter_event.dart';
import 'package:calmly/src/components/calm_box/modern_calm_box.dart';
import 'package:calmly/src/config/app_state.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, appState, __) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                appState.isModernBox ? ModernCalmBox() : TraditionalCalmBox(),
                HomeWidget(),
              ],
            ),
          ),
        );
      },

      // body: TraditionalCalmBox(),
    );
  }
}

class HomeWidget extends StatefulWidget {
  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  BreatheBloc _breatheBloc;
  BreatheCounterBloc _breatheCounterBloc;
  bool isDark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _breatheBloc = Provider.of<BreatheBloc>(context);
    _breatheCounterBloc = Provider.of<BreatheCounterBloc>(context);
    isDark = context.read<AppState>().themeSetting == ThemeSetting.dark;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        // top: height * 0.1,
        bottom: height * 0.05,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // crossAxisAlignment: CrossAxisAlignment.baseline,
            // textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Focus /\nBreathe /\nRelax /\n",
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(
                      CustomIcons.dot_3,
                      size: width * 0.1,
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000),
                    ),
                    onPressed: () {
                      Scaffold.of(context)
                          .showBottomSheet((BuildContext context) {
                        return SettingsBottomSheet();
                      });
                    },
                  ),
                ],
              ),
              StreamBuilder(
                initialData: 04,
                stream: _breatheCounterBloc.outBreatheCounter,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  int breatheCount = snapshot.data;
                  if (breatheCount == 0 || breatheCount == -1) {
                    breatheCount = 4;
                  }
                  return Text(
                    '$breatheCount',
                    style: const TextStyle(
                        fontSize: 100, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ), //upper widgets
          StreamBuilder(
            stream: _breatheBloc.outBreathe,
            initialData: Breathe.idle,
            builder: (BuildContext context, AsyncSnapshot<Breathe> snapshot) {
              Breathe breathe = snapshot.data;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mapBreathingInfo(breathe),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Visibility(
                    visible: breathe != Breathe.idle,
                    child: GestureDetector(
                      onTap: () {
                        _breatheCounterBloc.inBreatheCounterEvent
                            .add(EndBreatheCounterEvent());
                      },
                      child: Text(
                        'End now',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Text(
                    '08',
                    style: const TextStyle(
                        fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ), //borrom widgets
        ],
      ),
    );
  }

  String mapBreathingInfo(Breathe breathe) {
    String breatheInfo;
    if (breathe == Breathe.inhale) {
      breatheInfo = 'Inhale\nfrom your\nnose';
    } else if (breathe == Breathe.holdBreathe) {
      breatheInfo = 'Hold\nyour\nbreathe';
    } else if (breathe == Breathe.exhale) {
      breatheInfo = 'Exhale\nfrom your\nmouth';
    }
    if (breathe == Breathe.idle) {
      breatheInfo = 'Tap\nCircle to\nstart';
    }
    return breatheInfo;
  }
}

class CountDown extends StatefulWidget {
  const CountDown({
    Key key,
    this.countDownTime,
  }) : super(key: key);
  final int countDownTime;
  @override
  _CountDownState createState() => _CountDownState();
}

class _CountDownState extends State<CountDown> {
  Timer _timer;
  var _start = 4;
  void startTimer() {
    // _start = widget.countDownTime;
    var time = Duration(seconds: widget.countDownTime);
    _timer = new Timer.periodic(
      time,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    startTimer();
    return Text(
      '$_start',
      style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}