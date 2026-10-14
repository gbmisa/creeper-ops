import subprocess, re, os, sys, glob
S = "/tmp/claude-1000/s"
LIB = glob.glob(S + "/lib/Prepared*")[0]
K = S + "/k/"
OUT = S + "/out"
TMP = S + "/tmpw"
os.makedirs(TMP, exist_ok=True)
def sh(*a):
    r = subprocess.run(a, capture_output=True, text=True)
    if r.returncode: print("ERR", a, r.stderr[-300:]); sys.exit(1)
    return r.stderr
FAM = {"1911": ("1911", "A_42P", "A_34P"), "ppq": ("Walther PPQ", "X_39P", "X_31P"), "cg": ("Carl Gustav M45", "G_31P", "G_20P"),
 "ak": ("AK-47", "C_28P", "C_31P"), "sks": ("SKS", "U_14P", "U_19P"), "ar15": ("AR-15", "D_32P", "D_24P"), "mosin": ("Mosin Nagant", "M_21P", "M_26P"),
 "1917": ("1917", "B_24P", "B_16P"), "tikka": ("Tikka", "W_29P", "W_24P"), "savage": ("Savage 10 .300 Blackout", "T_27P", "T_17P"),
 "model12": ("Model 12", "K_22P", "K_17P"), "nova": ("Nova", "O_21P", "O_17P"), "ppsh": ("PPSh", "P_30P", "P_16P")}
def onset(path):
    e = sh("ffmpeg", "-hide_banner", "-i", path, "-af", "silencedetect=n=-35dB:d=0.2", "-f", "null", "-")
    ends = [float(x) for x in re.findall(r"silence_end: ([0-9.]+)", e)]
    starts = [float(x) for x in re.findall(r"silence_start: ([0-9.]+)", e)]
    o = ends[0] if ends and (not starts or starts[0] < 0.01) else 0.0
    nxt = [s for s in starts if s > o + 0.1]
    return o, (nxt[0] if nxt else o + 2.0)
def enc(wav, name):
    sh("ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "3", OUT + "/" + name + ".ogg")
def sox(out, *a):
    sh("sox", *a[:1], out, *a[1:]) if False else sh("sox", *a)
def shot(key, tail=False):
    d, near, mid = FAM[key]
    src = f"{LIB}/{d}/{mid if tail else near}.wav"
    o, nxt = onset(src)
    dur = min(max(nxt - o + 0.2, 0.5), 3.2 if tail else 1.8)
    w = f"{TMP}/{key}{'_t' if tail else ''}.wav"
    sh("sox", src, w, "remix", "-", "trim", f"{max(o-0.02,0):.3f}", f"{dur:.3f}", "fade", "t", "0.0", f"{dur:.3f}", f"{min(0.5, dur/2):.3f}", "norm", "-3")
    return w
def derive(w, name, *fx):
    o = f"{TMP}/{name}.wav"; sh("sox", w, o, *fx); return o
def mix(name, a, b, wa=1.0, wb=0.6):
    o = f"{TMP}/{name}.wav"
    sh("sox", "-m", "-v", str(wa), a, "-v", str(wb), b, o, "norm", "-3"); return o
base = {}
for k in FAM:
    base[k] = shot(k); enc(base[k], "shot_" + k)
    t = shot(k, True); enc(t, "tail_" + k)
# derived calibre voices
enc(mix("r44", derive(base["1911"], "a44", "speed", "0.72"), derive(base["savage"], "b44", "speed", "0.55", "lowpass", "900"), 1.0, 0.9), "shot_44mag")
enc(derive(base["cg"], "vec", "speed", "0.88"), "shot_vector")
enc(derive(base["ppsh"], "p90", "speed", "1.3"), "shot_p90")
enc(derive(base["tikka"], "scar", "speed", "0.9"), "shot_scar")
enc(derive(base["savage"], "sr25", "speed", "0.93"), "shot_sr25")
enc(mix("a338", derive(base["tikka"], "t338", "speed", "0.72"), derive(base["1917"], "b338", "speed", "0.55", "lowpass", "700"), 1.0, 0.9), "shot_338")
enc(mix("pkm", derive(base["mosin"], "m54", "speed", "0.92"), derive(base["ak"], "a54", "speed", "0.7", "lowpass", "800"), 1.0, 0.7), "shot_pkm")
enc(derive(base["nova"], "saiga", "speed", "1.08"), "shot_saiga")
# suppressed
sh("sox", f"{TMP}/../raw/silencer.wav", f"{TMP}/sil.wav", "remix", "-", "trim", "0", "1.2", "fade", "t", "0", "1.2", "0.5", "norm", "-3"); enc(f"{TMP}/sil.wav", "sup_pistol")
for nm, key, sp in (("smg", "cg", "1.0"), ("rifle", "ar15", "1.0"), ("shotgun", "nova", "0.9"), ("sniper", "tikka", "0.95"), ("heavy", "mosin", "0.85")):
    enc(derive(base[key], "sup_" + nm, "speed", sp, "lowpass", "1600", "gain", "-3", "fade", "t", "0", "0.9", "0.35", "norm", "-5"), "sup_" + nm)
# mechanical
R = S + "/raw/"
def trimsil(src, name, *fx):
    w = f"{TMP}/{name}.wav"
    sh("sox", src, w, "remix", "-", "silence", "1", "0.01", "1%", *fx, "norm", "-4"); enc(w, name)
    return w
def cut(src, name, st, du, *fx):
    w = f"{TMP}/{name}.wav"
    sh("sox", src, w, "remix", "-", "trim", str(st), str(du), "fade", "t", "0.005", str(du), "0.03", *fx, "norm", "-4"); enc(w, name); return w
def ogg(path, name, *fx):
    w = f"{TMP}/{name}.wav"; sh("sox", path, w, "remix", "-", *fx, "norm", "-4"); enc(w, name); return w
cut(R+"arreload.wav", "rifle_mag_out", 0, 0.55); cut(R+"arreload.wav", "rifle_mag_in", 0.5, 1.05); cut(R+"arreload.wav", "rifle_charge", 1.0, 0.55)
trimsil(R+"gunreload1.wav", "pistol_mag_in"); ogg(R+"clipload1.wav", "pistol_mag_out"); 
cut(R+"reload.wav", "pistol_slide", 0.55, 1.0)
trimsil(S+"/sn/gun_reload.1.ogg", "smg_mag_in"); ogg(R+"clipload2.wav", "smg_mag_out"); trimsil(S+"/sn/gun_reload.2.ogg", "lmg_belt_in")
SG = S + "/sg/ShotgunSounds/"
trimsil(SG+"Rack.mp3", "shotgun_pump"); cut(SG+"Subsequent Shells.mp3", "shotgun_shell_in", 0.6, 0.9); ogg(R+"singlebullet.wav", "round_in")
ogg(R+"shotguncock.wav", "saiga_charge"); ogg(R+"lockclick.mp3", "dry_click"); 
sh("sox", "-m", R+"lockclick.mp3", S+"/k/kenney_rpg-audio/Audio/metalLatch.ogg", f"{TMP}/bolt.wav", "pad", "0", "0.15", "norm", "-4") if False else None
w = f"{TMP}/bolt_a.wav"; sh("sox", R+"lockclick.mp3", w, "remix", "-", "pad", "0", "0.2")
w2 = f"{TMP}/bolt_b.wav"; sh("sox", S+"/k/kenney_rpg-audio/Audio/metalLatch.ogg", w2, "remix", "-", "pad", "0.18", "0")
sh("sox", "-m", w, w2, f"{TMP}/bolt.wav", "norm", "-4"); enc(f"{TMP}/bolt.wav", "bolt_action")
cut(R+"eqclicks.wav", "belt_open", 1.0, 0.9); cut(R+"eqclicks.wav", "belt_close", 3.6, 0.8)
# ping (Garand): decaying 2.6 kHz sine pair
sh("sox", "-n", f"{TMP}/ping.wav", "synth", "0.9", "sine", "2650", "sine", "3980", "fade", "q", "0.002", "0.9", "0.8", "gain", "-8", "norm", "-6"); enc(f"{TMP}/ping.wav", "garand_ping")
# generic UI/foley from Kenney
def kn(pack, f, name, *fx):
    ogg(f"{K}kenney_{pack}/Audio/{f}.ogg", name, *fx)
kn("rpg-audio", "metalClick", "mode_click"); kn("rpg-audio", "metalLatch", "attach_latch")
kn("rpg-audio", "metalClick", "attach_sight_fit", "speed", "1.15"); kn("rpg-audio", "metalClick", "attach_sight_rem", "speed", "0.85")
kn("rpg-audio", "metalLatch", "attach_muzzle_fit", "speed", "0.8"); kn("rpg-audio", "metalLatch", "attach_muzzle_rem", "speed", "0.7")
kn("rpg-audio", "metalLatch", "attach_under_fit", "speed", "1.2"); kn("rpg-audio", "metalLatch", "attach_under_rem", "speed", "1.0")
ogg(R+"clipload2.wav", "attach_mag_fit", "speed", "0.9"); ogg(R+"clipload2.wav", "attach_mag_rem", "speed", "0.75")
for nm, pk, f in (("inv_cloth", "rpg-audio", "cloth2"), ("inv_leather", "rpg-audio", "handleSmallLeather"), ("inv_leather_big", "rpg-audio", "dropLeather"),
                  ("inv_coins", "rpg-audio", "handleCoins"), ("inv_metal", "impact-sounds", "impactMetal_light_001"), ("inv_metal_heavy", "impact-sounds", "impactMetal_medium_001"),
                  ("inv_soft", "impact-sounds", "impactSoft_medium_001"), ("inv_plastic", "impact-sounds", "impactGeneric_light_001"), ("inv_drop_gun", "impact-sounds", "impactPlate_medium_001"),
                  ("inv_wood", "impact-sounds", "impactWood_light_001")):
    kn(pk, f, nm)
kn("rpg-audio", "cloth3", "inv_cloth_move", "speed", "1.2"); kn("rpg-audio", "handleSmallLeather2", "inv_leather_move"); kn("rpg-audio", "handleCoins2", "inv_coins_move"); kn("rpg-audio", "metalClick", "inv_metal_move", "speed", "0.8")
# utility
ogg(S+"/k/kenney_sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg", "frag_blast")
w = mix("flb", ogg(S+"/k/kenney_sci-fi-sounds/Audio/explosionCrunch_000.ogg", "tmpcr", "speed", "1.5", "trim", "0", "0.7"), f"{TMP}/dummy.wav" if False else ogg(S+"/k/kenney_impact-sounds/Audio/impactMetal_heavy_000.ogg", "tmpmh", "speed", "1.8", "trim", "0", "0.5"), 1.0, 0.7); enc(w, "flash_bang")
sh("sox", "-n", f"{TMP}/tin.wav", "synth", "4.5", "sine", "7200", "sine", "7500", "fade", "t", "0.05", "4.5", "3.5", "gain", "-14", "norm", "-14"); enc(f"{TMP}/tin.wav", "flash_tinnitus")
sh("sox", "-n", f"{TMP}/hiss.wav", "synth", "3.5", "pinknoise", "highpass", "2500", "lowpass", "9000", "fade", "t", "0.05", "3.5", "1.2", "norm", "-6"); enc(f"{TMP}/hiss.wav", "smoke_hiss")
sh("sox", "-n", f"{TMP}/wh.wav", "synth", "0.45", "brownnoise", "bandpass", "900", "700", "fade", "t", "0.15", "0.45", "0.2", "norm", "-8"); enc(f"{TMP}/wh.wav", "throw_whoosh")
sh("sox", "-n", f"{TMP}/gf.wav", "synth", "0.35", "whitenoise", "bandpass", "2200", "1500", "fade", "t", "0.01", "0.35", "0.25", "norm", "-8"); enc(f"{TMP}/gf.wav", "grapple_fire")
sh("sox", "-n", f"{TMP}/reel.wav", "synth", "1.0", "square", "55", "tremolo", "28", "90", "lowpass", "1800", "gain", "-6", "norm", "-8"); enc(f"{TMP}/reel.wav", "grapple_reel")
kn("impact-sounds", "impactMetal_heavy_001", "grapple_impact", "speed", "1.1"); kn("impact-sounds", "impactMetal_light_002", "grenade_bounce"); kn("impact-sounds", "impactPlate_light_001", "smoke_bounce")
kn("rpg-audio", "metalLatch", "grenade_pin", "speed", "1.3"); kn("rpg-audio", "metalClick", "grapple_release", "speed", "0.7")
kn("rpg-audio", "clothBelt", "stim_use"); kn("rpg-audio", "cloth1", "binoc_raise"); kn("rpg-audio", "cloth4", "binoc_lower"); kn("rpg-audio", "metalClick", "binoc_zoom", "speed", "1.4")
print("done", len(glob.glob(OUT + "/*.ogg")))
