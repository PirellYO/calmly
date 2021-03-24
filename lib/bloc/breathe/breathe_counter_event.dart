import 'package:calmly/bloc/breathe/breathe_bloc.dart';

abstract class BreatheCounterEvent {}

class OneBreatheCounterEvent extends BreatheCounterEvent {}

class CompletedBreatheCounterEvent extends BreatheCounterEvent {}

class EndBreatheCounterEvent extends BreatheCounterEvent {}
