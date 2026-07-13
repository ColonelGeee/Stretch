///////////////////////////////
// STRETCH
///////////////////////////////

//
(
s.options.numWireBufs = 64 * 1024;
s.options.memSize = 8192 * 256;
s.reboot;
)

// check for your serial port and the arduino
SerialPort.listDevices;

// make a connection to the arduino
(
SerialPort.closeAll;
~port = SerialPort.new("/dev/cu.usbmodem11201", 115200); //change the name according to your arduino
~arduinoData = [];
~values = [];
CmdPeriod.doOnce({Tdef(\getData).stop;SerialPort.closeAll;});
);

// evaluate this to get the data from the arduino
(
Tdef(\getData, {
	~arduinoData = [];
	~values = [];
	loop{
		var data;
		data = ~port.read;
		case
		{data == nil} {nil}

		{(data.asAscii.isAlpha.not) && (data.asAscii.isPrint)}
		{~arduinoData = ~arduinoData.add(data.asAscii.asString)}

		{(data.asAscii.isAlpha)}
		{
			~values = ("[".catList(~arduinoData)++"]").interpret;
			~arduinoData = [];
		}

		{true}{nil};
	}
}).play;
)

// check, if you get values from the arduino
~values;
~values.size;

// set the effect bus and load the sample
(
s.newBusAllocators;
~test = Buffer.readChannel(s, "/Users/corneliusgromminger/Documents/KUG/6. Semester/Live-Elektronik/Samples/Igorrr1.wav", channels: [0]); // exchange the path to the sample, according to your place of storage
~bus = Bus.audio(s, 2);
);

// calculate the settings for the fft
(
~fftsize = 8192;
~hop = 0.125;
~win = 0;
);

// load the buffer according to the previous fft calculation
f = {Buffer.alloc(s, ~test.duration.calcPVRecSize(~fftsize, ~hop))} ! 2;

// start the player for the fft
(
{
	var sig, chain, localbuf;
	var env = EnvGen.ar(Env([1, 0.5, 1], [300, 10]));
	sig = PlayBuf.ar(1, ~test, BufRateScale.kr(~test), loop: 0, doneAction: 2);
	localbuf = { LocalBuf.new(~fftsize) } ! 2;
	chain = FFT(localbuf, sig, ~hop, ~win);
	chain = PV_RecordBuf(chain, f, run: 1, hop: ~hop, wintype: ~win);
	0;
}.play;
);

// start the effect chain and the synth
(
~eff = SynthDef(\eff, {
	arg out = 0, rot = 0.1, lfoFreq = 0.05, mixx = 1;
	var sig, inSig, rotation, rev;
	var env = EnvGen.ar(Env([0.01, 0.1, 1, 5], [240, 50, 30], ['lin', 'exp']));
	var env2 = EnvGen.ar(Env([200, 1000, 15000], [100, 300]));
	var lfo = SinOsc.ar(10).range(0, 1);
	var mix = EnvGen.ar(Env([0, 0, 1], [300, 20]));
	var rotBlend = EnvGen.ar(Env([0, 0, 1], [250, 10]));
	var revMix = EnvGen.ar(Env([0, 0, 1], [329, 1]));
	inSig = In.ar(~bus, 2);
	sig = inSig;
	m.do { |i|
		sig = AllpassC.ar(
			sig,
			SampleDur.ir * 2,
			SampleDur.ir,
			0
		);
		sig = FreqShift.ar(sig, 0, LFDNoise3.ar(lfoFreq).range(0, 2pi));
		sig = sig + inSig;
	};
	sig = LPF.ar(sig, env2);
	lfo = sig * lfo;
	sig = sig.blend(lfo, mix);
	rotation = Rotate2.ar(sig[0], sig[1], SinOsc.kr(env));
	sig = sig.blend(rotation, rotBlend);
	rev = FreeVerb2.ar(sig[0], sig [1], mixx, 0.7);
	sig = sig.blend(rev, revMix);
	OffsetOut.ar(out, Limiter.ar(sig.tanh));
}).play;
~synths = SynthDef(\scream, {
	arg out = 0, blend = 0, blend2 = 0.5, rot = 0.1, del = 1, dec = 0.1, stretch = 1, stretch2 = 2, freeze = 0, start = 0, pitch = 1, mix = 1, lfoSpeed = 10, amp = 0.2, ampBass = 0, lpf = 250, phase = 1;
	var env = EnvGen.ar(Env([1/500, 1/500, 2], [328, 2]));
	var envAmp = EnvGen.ar(Env([0.2, 0.2, 0], [330, 0.1]));
	var envFilt = EnvGen.ar(Env([200, 500, 20000], [120, 120]));
	var lfo = SinOsc.ar(lfoSpeed.lag(10)).range(0 ,1), comb, chain, sig, localbuf;
	var bass, sig2;
	localbuf = {LocalBuf.new(~fftsize) } ! 2;
	chain = PV_PlayBuf(localbuf, f, env, loop: 1);
	sig = IFFT(chain, ~win);
	sig2 = PitchShift.ar(sig, pitchRatio: pitch.lag(5));
	bass = LPF.ar(SinOscFB.ar([47, 47 * phase], pi, mul: ampBass.lag(5)), lpf);
	sig = Mix.ar([sig, sig2, bass]);
	lfo = sig * lfo;
	sig = sig.blend(lfo, blend.lag(2));
	sig = LPF.ar(sig, envFilt);
	XOut.ar(~bus, mix, sig * envAmp);
}).play;
);

// start the Tdef for changing the colors
(
Tdef(\changeColors, {
	loop{
		~views.do{
			arg view, index;
			var grayVal, trig, freeze, rot, blend, pitch, ampBass, phase;
			grayVal = ~values.collect({arg i; i.linlin(100, 300, 0, 1)});
			blend = ~values[0].linlin(270, 320, 0, 1); //set the range of the sensors here
			pitch = ~values[1].linlin(250, 300, 1, 2.5); //set the range of the sensors here
			ampBass = ~values[2].linlin(210, 240, 0, 1); //set the range of the sensors here
			phase = ~values[3].linlin(180, 220, 1, 2); //set the range of the sensors here
			view.background_(Color.gray(grayVal[index]));
			~synths.set(\blend, blend, \pitch, pitch, \ampBass, ampBass, \phase, phase);
			//~synths.set(\pitch, pitch, \ampBass, ampBass, \phase, phase);
		};
		0.01.wait;
	}
}).play(AppClock);
)

// evaluat this last to apply the changes from the sensor to the synth
(
Window.closeAll;
w = Window.new(bounds: Rect(380, 1580, 420, 120)).front;
~views = 4.collect { arg n;
	var row = n div: 4;
	var col = n % 4;
	CompositeView(w, Rect(10 + (col * 25), 10 + (row * 30), 25, 25))
	.background_(Color.gray(0.5));
};
)