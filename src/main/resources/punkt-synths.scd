(
SynthDef.new(\play1,
    {|amp=1, sus=1, pan=0, rate=1.0, bus=0, blur=1, buf=0|
        var osc, env;
        sus = sus * blur;
        osc = PlayBuf.ar(1, buf, (BufRateScale.ir(buf) * rate), doneAction: Done.freeSelf);
        osc = (osc * amp);
        osc = Mix(osc) * 0.5;
        osc = Pan2.ar(osc, pan);
        Out.ar(bus, osc)
}).add;

SynthDef.new(\play2,
    {|amp=1, sus=1, pan=0, rate=1.0, bus=0, blur=1, buf=0|
        var osc, env;
        sus = sus * blur;
        osc = PlayBuf.ar(2, buf, (BufRateScale.ir(buf) * rate), doneAction: Done.freeSelf);
        osc = (osc * amp);
        osc = Mix(osc) * 0.5;
        osc = Pan2.ar(osc, pan);
        Out.ar(bus, osc)
}).add;


SynthDef.new(\shape,
    {|freq=440, amp=0.5, dur=0.2, cutoff=1200, mix=0.2, release=0.2|
        var osc1, osc2, sine, adsr, snd, env, level;
        osc1 = LFTri.ar(freq);
        osc2 = LFSaw.ar(freq, 0.88);
        sine = SinOsc.ar(freq / 2);
        adsr = Env.adsr(0.01, 0.6, 0.1, release);
        snd = (osc2 * mix) + ((1 - mix) * osc1);
        env = EnvGen.kr(adsr, Line.kr(1.0, 0.0, dur/2), doneAction:2);
        // level = EnvGen.kr(adsr, Line.kr(1.0, 0.0, dur), levelScale: cutoff);
        snd = LPF.ar(snd, cutoff);
        snd = snd + (0.2 * sine);
        // snd = FreeVerb.ar(snd, room = 0.9);
        Out.ar(0, Pan2.ar(FreeVerb.ar(amp * env * snd, room: 0.2)));
}).add;

SynthDef.new(\sampler,
    {|bpm=118, total=4, beats=4, start=0, amp=1, cutoff=10000, buf=0|
        var beatLen, dur, env, rate, frames, pos, snd;
        beatLen = 60 / bpm;
        dur = beats * beatLen;
        env = EnvGen.ar(Env([1,1,0], [dur-0.2, 0.2], 'welch'));
        rate = BufDur.kr(buf) / (total * beatLen);
        frames = BufFrames.kr(buf);
        pos = (start / total) * frames;
        snd = PlayBuf.ar(2, buf, (rate * BufRateScale.ir(buf)), startPos: pos, doneAction: Done.freeSelf);
        snd = LPF.ar(snd, cutoff);
        Out.ar(0, Pan2.ar(snd * amp * env));
}).add;

SynthDef(\plucklead, {
    |out=0, dur=1, amp=1, freq=440, cutoff=7000, start=2000, sus=0.4, rel=0.8, pan = 1|
    var sound;
    var voices = 13;
    var env = Env.adsr(0.1, 0.2, sus, rel);
    var envGen = EnvGen.kr(env, Line.kr(1.0, 0.0, dur), doneAction:2);
    var freqs = {Rand(-2,2)*2**(freq/1200)}.dup(voices);
    var phases = Array.fill(voices, { 1.0.rand2 });
    sound =  LFSaw.ar(freq + freqs, phases);
    sound = LPF.ar(sound, start + cutoff);
    // sound = FreeVerb.ar(sound, mix: 0.5, room: 2);
    Out.ar(out, Pan2.ar(sound * amp, pan.fold(-1, 1), envGen));
}).add;

SynthDef(\tb303, {
    |out=0, freq=440, wave=1, cutoff=1000, res=0.1, start=100, sus=1, dec=0.1, dur=1, amp=1|
    var sound;
    var line = Line.ar(1, 0, dur*2, doneAction:2);
    var volEnv = EnvGen.ar(Env.perc(10e-10, dur), doneAction: 2);
    var filEnv = EnvGen.ar(Env.adsr(10e-10, dec, sus, 0.2), line);
    var waves = [Saw.ar(freq, volEnv), Pulse.ar(freq, 0.5, volEnv)];
    sound = RLPF.ar(Select.ar(wave, waves), start + (filEnv * cutoff), res).dup;
    // sound = FreeVerb.ar(sound, room: 2, mix: 0.9);
    sound = (sound.clip2(0.1) * 6).distort();
    Out.ar(out, sound * amp);

}).add;

SynthDef(\tr808, {
    |out=0, dur=1, amp=1, freq=440, cutoff=1200, start=1000, release=0.3|
    var sound, filEnv, filGen;
    var ampEnv = Env.adsr(0.01, 0.5, 0.2, release);
    var ampGen = EnvGen.kr(ampEnv, Line.kr(1.0, 0.0, dur/2), doneAction: 2);
    var osc1 = SinOsc.ar(freq);
    var osc2 = Pulse.ar(freq*2);
    sound =  Mix.ar(osc1, 0.8 * osc2);
    sound =  Splay.ar(sound);
    filEnv = Env.adsr(0.2, 0.4, 0.1, 0.5);
    filGen = EnvGen.kr(filEnv, Line.kr(1.0, 0.0, dur), levelScale: cutoff);
    sound = LPF.ar(sound, start + filGen);
    sound = BPeakEQ.ar(sound, 700, 3, 3);
    Out.ar(out, Pan2.ar(sound * amp * ampGen));
}).add;

SynthDef(\dafunk, {
    |out=0, dur=1, amp=1, freq=440, cutoff=1200, start=250, sus = 0.5, rel=0.2|
    var osc = Mix.ar([Saw.ar(freq), Saw.ar(freq * 0.7491535384383409)]);
    var env = Env.adsr(0.3, 0.2, sus, rel);
    var envGen = EnvGen.ar(env, Line.kr(1.0, 0.0, dur/2), doneAction:2);
    var filEnv = Env.adsr(0.4, 0.5, 0.2, 0.5);
    var filGen = EnvGen.kr(filEnv, Line.kr(1.0, 0.0, dur/2), levelScale: cutoff);
    var sound = BPF.ar(osc, start + filGen, 0.5);
    sound = Pan2.ar(sound * amp * envGen);
    sound = (sound.clip2(0.007) * 24).distort();
    sound = FreeVerb.ar(sound, mix: 0.4, room: 1.8);
    Out.ar(out, sound);
}).add;
)
