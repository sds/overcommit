# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PrePush::FlutterTest do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when flutter test exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when flutter test exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'with a runtime error' do
      before do
        result.stub(stdout: '', stderr: <<-MSG)
          0:03 +0: Counter increments smoke test
          ══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
          The following _Exception was thrown running a test:
          Exception

          When the exception was thrown, this was the stack:
          #0      main.<anonymous closure> (file:///Users/user/project/test/widget_test.dart:18:5)
          <asynchronous suspension>
          #1      main.<anonymous closure> (file:///Users/user/project/test/widget_test.dart)
          #2      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:146:29)
          <asynchronous suspension>
          #3      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart)
          #4      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:784:19)
          <asynchronous suspension>
          #7      TestWidgetsFlutterBinding._runTest (package:flutter_test/src/binding.dart:764:14)
          #8      AutomatedTestWidgetsFlutterBinding.runTest.<anonymous closure> (package:flutter_test/src/binding.dart:1173:24)
          #9      FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:178:54)
          #14     withClock (package:clock/src/default.dart:48:10)
          #15     FakeAsync.run.<anonymous closure> (package:fake_async/fake_async.dart:178:22)
          #20     FakeAsync.run (package:fake_async/fake_async.dart:178:7)
          #21     AutomatedTestWidgetsFlutterBinding.runTest (package:flutter_test/src/binding.dart:1170:15)
          #22     testWidgets.<anonymous closure> (package:flutter_test/src/widget_tester.dart:138:24)
          #23     Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:175:19)
          <asynchronous suspension>
          #24     Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart)
          #29     Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:173:13)
          #30     Invoker.waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:231:15)
          #35     Invoker.waitForOutstandingCallbacks (package:test_api/src/backend/invoker.dart:228:5)
          #36     Invoker._onRun.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart:383:17)
          <asynchronous suspension>
          #37     Invoker._onRun.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart)
          #42     Invoker._onRun.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart:370:9)
          #43     Invoker._guardIfGuarded (package:test_api/src/backend/invoker.dart:415:15)
          #44     Invoker._onRun.<anonymous closure> (package:test_api/src/backend/invoker.dart:369:7)
          #51     Invoker._onRun (package:test_api/src/backend/invoker.dart:368:11)
          #52     LiveTestController.run (package:test_api/src/backend/live_test_controller.dart:153:11)
          #53     RemoteListener._runLiveTest.<anonymous closure> (package:test_api/src/remote_listener.dart:256:16)
          #58     RemoteListener._runLiveTest (package:test_api/src/remote_listener.dart:255:5)
          #59     RemoteListener._serializeTest.<anonymous closure> (package:test_api/src/remote_listener.dart:208:7)
          #77     _GuaranteeSink.add (package:stream_channel/src/guarantee_channel.dart:125:12)
          #78     new _MultiChannel.<anonymous closure> (package:stream_channel/src/multi_channel.dart:159:31)
          #82     CastStreamSubscription._onData (dart:_internal/async_cast.dart:85:11)
          #116    new _WebSocketImpl._fromSocket.<anonymous closure> (dart:_http/websocket_impl.dart:1145:21)
          #124    _WebSocketProtocolTransformer._messageFrameEnd (dart:_http/websocket_impl.dart:338:23)
          #125    _WebSocketProtocolTransformer.add (dart:_http/websocket_impl.dart:232:46)
          #135    _Socket._onData (dart:io-patch/socket_patch.dart:2044:41)
          #144    new _RawSocket.<anonymous closure> (dart:io-patch/socket_patch.dart:1580:33)
          #145    _NativeSocket.issueReadEvent.issue (dart:io-patch/socket_patch.dart:1076:14)
          (elided 111 frames from dart:async and package:stack_trace)

          The test description was:
            Counter increments smoke test
          ════════════════════════════════════════════════════════════════════════════════════════════════════
          00:03 +0 -1: Counter increments smoke test [E]
            Test failed. See exception logs above.
            The test description was: Counter increments smoke test

          00:03 +0 -1: Some tests failed.
        MSG
      end

      it { should fail_hook }
    end

    context 'with a test failure' do
      before do
        result.stub(stderr: '', stdout: <<-MSG)
          00:02 +0: Counter increments smoke test
          ══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
          The following TestFailure object was thrown running a test:
            Expected: exactly one matching node in the widget tree
            Actual: _TextFinder:<zero widgets with text "1" (ignoring offstage widgets)>
             Which: means none were found but one was expected

          When the exception was thrown, this was the stack:
          #4      main.<anonymous closure> (file:///Users/user/project/test/widget_test.dart:19:5)
          <asynchronous suspension>
          #5      main.<anonymous closure> (file:///Users/user/project/test/widget_test.dart)
          #6      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:146:29)
          <asynchronous suspension>
          #7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart)
          #8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:784:19)
          <asynchronous suspension>
          #11     TestWidgetsFlutterBinding._runTest (package:flutter_test/src/binding.dart:764:14)
          #12     AutomatedTestWidgetsFlutterBinding.runTest.<anonymous closure> (package:flutter_test/src/binding.dart:1173:24)
          #13     FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:178:54)
          #18     withClock (package:clock/src/default.dart:48:10)
          #19     FakeAsync.run.<anonymous closure> (package:fake_async/fake_async.dart:178:22)
          #24     FakeAsync.run (package:fake_async/fake_async.dart:178:7)
          #25     AutomatedTestWidgetsFlutterBinding.runTest (package:flutter_test/src/binding.dart:1170:15)
          #26     testWidgets.<anonymous closure> (package:flutter_test/src/widget_tester.dart:138:24)
          #27     Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:175:19)
          <asynchronous suspension>
          #28     Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart)
          #33     Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:173:13)
          #34     Invoker.waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:231:15)
          #39     Invoker.waitForOutstandingCallbacks (package:test_api/src/backend/invoker.dart:228:5)
          #40     Invoker._onRun.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart:383:17)
          <asynchronous suspension>
          #41     Invoker._onRun.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart)
          #46     Invoker._onRun.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/invoker.dart:370:9)
          #47     Invoker._guardIfGuarded (package:test_api/src/backend/invoker.dart:415:15)
          #48     Invoker._onRun.<anonymous closure> (package:test_api/src/backend/invoker.dart:369:7)
          #55     Invoker._onRun (package:test_api/src/backend/invoker.dart:368:11)
          #56     LiveTestController.run (package:test_api/src/backend/live_test_controller.dart:153:11)
          #57     RemoteListener._runLiveTest.<anonymous closure> (package:test_api/src/remote_listener.dart:256:16)
          #62     RemoteListener._runLiveTest (package:test_api/src/remote_listener.dart:255:5)
          #63     RemoteListener._serializeTest.<anonymous closure> (package:test_api/src/remote_listener.dart:208:7)
          #81     _GuaranteeSink.add (package:stream_channel/src/guarantee_channel.dart:125:12)
          #82     new _MultiChannel.<anonymous closure> (package:stream_channel/src/multi_channel.dart:159:31)
          #86     CastStreamSubscription._onData (dart:_internal/async_cast.dart:85:11)
          #120    new _WebSocketImpl._fromSocket.<anonymous closure> (dart:_http/websocket_impl.dart:1145:21)
          #128    _WebSocketProtocolTransformer._messageFrameEnd (dart:_http/websocket_impl.dart:338:23)
          #129    _WebSocketProtocolTransformer.add (dart:_http/websocket_impl.dart:232:46)
          #139    _Socket._onData (dart:io-patch/socket_patch.dart:2044:41)
          #148    new _RawSocket.<anonymous closure> (dart:io-patch/socket_patch.dart:1580:33)
          #149    _NativeSocket.issueReadEvent.issue (dart:io-patch/socket_patch.dart:1076:14)
          (elided 111 frames from dart:async and package:stack_trace)

          This was caught by the test expectation on the following line:
            file:///Users/user/project/test/widget_test.dart line 19
          The test description was:
            Counter increments smoke test
          ════════════════════════════════════════════════════════════════════════════════════════════════════
          00:02 +0 -1: Counter increments smoke test [E]
            Test failed. See exception logs above.
            The test description was: Counter increments smoke test

          00:02 +0 -1: Some tests failed.
        MSG
      end

      it { should fail_hook }
    end
  end
end
